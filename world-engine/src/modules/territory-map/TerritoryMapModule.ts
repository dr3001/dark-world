import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class TerritoryMapModule extends WorldEngineModule {
  name = "TerritoryMapModule";
  override async initialize() { console.log("[TerritoryMapModule] Initialized — strategic map ready"); }
  async getMap() { return (await query("SELECT * FROM territory_map ORDER BY name")).rows; }
  async getById(id: string) { return (await query("SELECT * FROM territory_map WHERE id = $1", [id])).rows[0]; }
  async getResources(territoryId: string) { return (await query("SELECT * FROM territory_resources WHERE territory_id = $1", [territoryId])).rows; }
}
