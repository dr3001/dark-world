import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class TroopModule extends WorldEngineModule {
  name = "TroopModule";
  override async initialize() { console.log("[TroopModule] Initialized — 7 troop types"); }
  async getTypes() { return (await query("SELECT * FROM troop_types ORDER BY category, name")).rows; }
  async getSquads(characterId: string) { return (await query("SELECT ts.*,tt.name as troop_name,tt.category FROM troop_squads ts JOIN troop_types tt ON ts.troop_type_id=tt.id WHERE ts.character_id=$1", [characterId])).rows; }
}
