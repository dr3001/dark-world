import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class QuestModule extends WorldEngineModule {
  name = "QuestModule";

  override async initialize() {
    console.log("[QuestModule] Initialized");
  }

  async getAvailableQuests(characterLevel: number = 1) {
    const r = await query("SELECT * FROM quest_data WHERE min_level <= $1 ORDER BY min_level, name", [characterLevel]);
    return r.rows;
  }

  async getQuestById(questId: string) {
    const r = await query("SELECT * FROM quest_data WHERE id = $1", [questId]);
    return r.rows[0] || null;
  }

  async getCharacterQuests(characterId: string) {
    const r = await query(
      `SELECT qp.*, qd.name as quest_name, qd.description, qd.quest_type, qd.rewards
       FROM quest_progress qp JOIN quest_data qd ON qp.quest_id = qd.id
       WHERE qp.character_id = $1 ORDER BY qp.created_at DESC`, [characterId]
    );
    return r.rows;
  }

  async acceptQuest(characterId: string, questId: string) {
    const existing = await query("SELECT * FROM quest_progress WHERE character_id = $1 AND quest_id = $2", [characterId, questId]);
    if (existing.rows[0]) return { error: "Quest already tracked", state: existing.rows[0].state };

    const r = await query(
      `INSERT INTO quest_progress (character_id, quest_id, state, started_at)
       VALUES ($1,$2,'active',NOW()) RETURNING *`, [characterId, questId]
    );
    await query(
      "INSERT INTO audit_logs (actor_type, actor_id, action, payload) VALUES ('character',$1,'quest_accepted',$2)",
      [characterId, JSON.stringify({ questId })]
    );
    return { action: "accepted", quest: r.rows[0] };
  }

  async completeQuest(characterId: string, questId: string) {
    const r = await query(
      "UPDATE quest_progress SET state = 'completed', completed_at = NOW(), updated_at = NOW() WHERE character_id = $1 AND quest_id = $2 AND state = 'active' RETURNING *",
      [characterId, questId]
    );
    if (!r.rows[0]) return { error: "Quest not active" };
    return { action: "completed", quest: r.rows[0] };
  }

  async updateProgress(characterId: string, questId: string, progressData: Record<string, unknown>) {
    await query(
      "UPDATE quest_progress SET progress = $1, updated_at = NOW() WHERE character_id = $2 AND quest_id = $3",
      [JSON.stringify(progressData), characterId, questId]
    );
  }
}
