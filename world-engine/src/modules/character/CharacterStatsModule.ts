import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";
import { xpForLevel } from "../../core/rpg-types.js";

export class CharacterStatsModule extends WorldEngineModule {
  name = "CharacterStatsModule";

  override async initialize() {
    console.log("[CharacterStatsModule] Initialized");
  }

  async getStats(characterId: string) {
    const r = await query("SELECT * FROM character_stats WHERE character_id = $1", [characterId]);
    return r.rows[0] || null;
  }

  async ensureStats(characterId: string) {
    const existing = await this.getStats(characterId);
    if (existing) return existing;
    const r = await query(
      "INSERT INTO character_stats (character_id) VALUES ($1) ON CONFLICT (character_id) DO NOTHING RETURNING *",
      [characterId]
    );
    return r.rows[0] || (await this.getStats(characterId));
  }

  async addXP(characterId: string, amount: number) {
    const stats = await this.ensureStats(characterId);
    const newXP = stats.xp + amount;
    let newLevel = stats.level;
    while (newXP >= xpForLevel(newLevel + 1) && newLevel < 100) {
      newLevel++;
    }
    const leveledUp = newLevel > stats.level;
    const hpGain = leveledUp ? (newLevel - stats.level) * 10 : 0;
    const manaGain = leveledUp ? (newLevel - stats.level) * 5 : 0;

    await query(
      `UPDATE character_stats SET xp = $1, level = $2,
       max_hp = max_hp + $3, hp = LEAST(hp + $3, max_hp + $3),
       max_mana = max_mana + $4, mana = LEAST(mana + $4, max_mana + $4),
       updated_at = NOW() WHERE character_id = $5`,
      [newXP, newLevel, hpGain, manaGain, characterId]
    );

    if (leveledUp) {
      await query(
        "INSERT INTO audit_logs (actor_type, actor_id, action, payload) VALUES ('system','stats_module','level_up',$1)",
        [JSON.stringify({ characterId, oldLevel: stats.level, newLevel, xp: newXP })]
      );
    }
    return { xp: newXP, level: newLevel, leveledUp };
  }

  async updateStat(characterId: string, stat: string, value: number) {
    const allowed = ["hp","max_hp","mana","max_mana","strength","dexterity","intelligence","vitality","charisma","luck"];
    if (!allowed.includes(stat)) throw new Error(`Invalid stat: ${stat}`);
    await query(`UPDATE character_stats SET ${stat} = $1, updated_at = NOW() WHERE character_id = $2`, [value, characterId]);
  }
}
