import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class ClassModule extends WorldEngineModule {
  name = "ClassModule";
  override async initialize() { console.log("[ClassModule] Initialized — 10 hero classes"); }
  async getAll() { return (await query("SELECT * FROM hero_classes ORDER BY name")).rows; }
  async getById(id: string) { return (await query("SELECT * FROM hero_classes WHERE id = $1", [id])).rows[0]; }
  async assignClass(characterId: string, classId: string) {
    await query("UPDATE character_origins SET class_id = $1 WHERE character_id = $2", [classId, characterId]);
  }
  async getOrigin(characterId: string) {
    return (await query("SELECT co.*, hc.name as class_name FROM character_origins co LEFT JOIN hero_classes hc ON co.class_id = hc.id WHERE co.character_id = $1", [characterId])).rows[0];
  }
  async ensureOrigin(characterId: string) {
    const existing = await this.getOrigin(characterId);
    if (existing) return existing;
    await query("INSERT INTO character_origins (character_id) VALUES ($1) ON CONFLICT DO NOTHING", [characterId]);
    return this.getOrigin(characterId);
  }
}
