import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class LoreModule extends WorldEngineModule {
  name = "LoreModule";
  override async initialize() { console.log("[LoreModule] Initialized — narrative engine ready"); }

  async getCharacterLore(characterId: string) {
    const bio = (await query("SELECT * FROM character_biographies WHERE character_id = $1", [characterId])).rows[0];
    const timeline = (await query("SELECT * FROM character_timeline WHERE character_id = $1 ORDER BY created_at DESC LIMIT 20", [characterId])).rows;
    const rep = (await query("SELECT * FROM character_reputation WHERE character_id = $1", [characterId])).rows;
    const titles = (await query("SELECT * FROM character_titles_earned WHERE character_id = $1", [characterId])).rows;
    return { bio, timeline, reputation: rep, titles };
  }

  async getClanLore(clanId: string) {
    const lore = (await query("SELECT * FROM clan_lore WHERE clan_id = $1", [clanId])).rows[0];
    const chronicles = (await query("SELECT * FROM clan_chronicles WHERE clan_id = $1 ORDER BY created_at DESC LIMIT 20", [clanId])).rows;
    return { lore, chronicles };
  }

  async getKingdomLore(kingdomId: string) {
    const lore = (await query("SELECT * FROM kingdom_lore WHERE kingdom_id = $1", [kingdomId])).rows[0];
    const chronicles = (await query("SELECT * FROM kingdom_chronicles WHERE kingdom_id = $1 ORDER BY created_at DESC LIMIT 20", [kingdomId])).rows;
    return { lore, chronicles };
  }

  async getTerritoryLore(territoryId: string) {
    const lore = (await query("SELECT * FROM territory_lore WHERE territory_id = $1", [territoryId])).rows[0];
    const chronicles = (await query("SELECT * FROM territory_chronicles WHERE territory_id = $1 ORDER BY created_at DESC LIMIT 20", [territoryId])).rows;
    return { lore, chronicles };
  }

  async getNPCLore(npcName: string) {
    return (await query("SELECT * FROM npc_lore WHERE npc_name = $1", [npcName])).rows[0];
  }

  async getWorldChronicles(limit: number = 20) {
    return (await query("SELECT * FROM world_chronicles WHERE is_public = true ORDER BY created_at DESC LIMIT $1", [limit])).rows;
  }

  async addTimelineEntry(characterId: string, eventType: string, title: string, description: string = "") {
    await query("INSERT INTO character_timeline (character_id, event_type, title, description) VALUES ($1,$2,$3,$4)", [characterId, eventType, title, description]);
  }

  async addWorldChronicle(eventType: string, title: string, description: string = "") {
    await query("INSERT INTO world_chronicles (event_type, title, description) VALUES ($1,$2,$3)", [eventType, title, description]);
  }
}
