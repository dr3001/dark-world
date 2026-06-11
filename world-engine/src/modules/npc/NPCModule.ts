import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class NPCModule extends WorldEngineModule {
  name = "NPCModule";

  override async initialize() {
    console.log("[NPCModule] Initialized — AI providers: openai-compatible, deepseek-compatible");
  }

  async getProfile(entityId: string) {
    const r = await query("SELECT * FROM npc_profiles WHERE entity_id = $1", [entityId]);
    return r.rows[0] || null;
  }

  async ensureProfile(entityId: string, role: string = "villager") {
    const existing = await this.getProfile(entityId);
    if (existing) return existing;
    const r = await query(
      "INSERT INTO npc_profiles (entity_id, role) VALUES ($1,$2) ON CONFLICT (entity_id) DO NOTHING RETURNING *",
      [entityId, role]
    );
    return r.rows[0] || (await this.getProfile(entityId));
  }

  async updatePersonality(entityId: string, personality: Record<string, unknown>) {
    await query("UPDATE npc_profiles SET personality = $1, updated_at = NOW() WHERE entity_id = $2", [JSON.stringify(personality), entityId]);
  }

  async updateKnowledge(entityId: string, knowledge: Record<string, unknown>) {
    await query("UPDATE npc_profiles SET knowledge = $1, updated_at = NOW() WHERE entity_id = $2", [JSON.stringify(knowledge), entityId]);
  }

  async setAIProvider(entityId: string, provider: string, config: Record<string, unknown>) {
    await query("UPDATE npc_profiles SET ai_provider = $1, ai_config = $2, updated_at = NOW() WHERE entity_id = $3", [provider, JSON.stringify(config), entityId]);
  }

  async addMemory(npcEntityId: string, characterId: string | null, memoryType: string, content: Record<string, unknown>, importance: number = 5) {
    const r = await query(
      "INSERT INTO npc_memory (npc_entity_id, character_id, memory_type, content, importance) VALUES ($1,$2,$3,$4,$5) RETURNING *",
      [npcEntityId, characterId, memoryType, JSON.stringify(content), importance]
    );
    return r.rows[0];
  }

  async getMemories(npcEntityId: string, characterId?: string, limit: number = 20) {
    let sql = "SELECT * FROM npc_memory WHERE npc_entity_id = $1";
    const params: unknown[] = [npcEntityId];
    if (characterId) {
      sql += " AND character_id = $2";
      params.push(characterId);
    }
    sql += " ORDER BY importance DESC, created_at DESC LIMIT $" + (params.length + 1);
    params.push(limit);
    const r = await query(sql, params);
    return r.rows;
  }

  async buildContext(npcEntityId: string, characterId: string) {
    const profile = await this.getProfile(npcEntityId);
    const memories = await this.getMemories(npcEntityId, characterId, 10);
    return { profile, memories, timestamp: new Date().toISOString() };
  }
}
