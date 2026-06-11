import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class AntiCheatModule extends WorldEngineModule {
  name = "AntiCheatModule";
  override async initialize() { console.log("[AntiCheat] Initialized — server-authoritative validation"); }

  async logCheatEvent(userId: string | null, characterId: string | null, cheatType: string, evidence: Record<string, unknown> = {}, confidence: number = 50) {
    return (await query("INSERT INTO anti_cheat_events (user_id, character_id, cheat_type, evidence, confidence) VALUES ($1,$2,$3,$4,$5) RETURNING *", [userId, characterId, cheatType, JSON.stringify(evidence), confidence])).rows[0];
  }

  async validateMovement(characterId: string, x: number, y: number, z: number): Promise<boolean> {
    const prev = (await query("SELECT * FROM movement_validations WHERE character_id = $1 ORDER BY created_at DESC LIMIT 1", [characterId])).rows[0];
    if (prev) {
      const dist = Math.sqrt((x - parseFloat(prev.x)) ** 2 + (z - parseFloat(prev.z)) ** 2);
      const speed = dist; // per tick (2s)
      await query("INSERT INTO movement_validations (character_id, x, y, z, speed, valid) VALUES ($1,$2,$3,$4,$5,$6)", [characterId, x, y, z, speed, speed < 30]);
      if (speed > 30) {
        await this.logCheatEvent(null, characterId, "speed_hack", { speed, x, y, z }, 80);
        return false;
      }
      if (speed === 0 && dist > 100) {
        await this.logCheatEvent(null, characterId, "teleport", { dist, x, y, z }, 90);
        return false;
      }
    } else {
      await query("INSERT INTO movement_validations (character_id, x, y, z, speed, valid) VALUES ($1,$2,$3,$4,0,true)", [characterId, x, y, z]);
    }
    return true;
  }

  async getCheatEvents(limit: number = 50) {
    return (await query("SELECT ace.*, ap.display_name FROM anti_cheat_events ace LEFT JOIN accounts_profile ap ON ace.user_id = ap.id ORDER BY ace.created_at DESC LIMIT $1", [limit])).rows;
  }
}
