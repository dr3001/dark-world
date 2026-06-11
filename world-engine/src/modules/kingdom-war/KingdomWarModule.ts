import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class KingdomWarModule extends WorldEngineModule {
  name = "KingdomWarModule";
  override async initialize() { console.log("[KingdomWarModule] Initialized"); }
  async create(name: string, tag: string, rulerUserId: string, originClanId: string) {
    return (await query("INSERT INTO kingdom_registry (name,tag,ruler_user_id,origin_clan_id) VALUES ($1,$2,$3,$4) RETURNING *", [name, tag, rulerUserId, originClanId])).rows[0];
  }
  async getAll() { return (await query("SELECT * FROM kingdom_registry ORDER BY level DESC, name")).rows; }
  async getMembers(kingdomId: string) { return (await query("SELECT km.*,ap.display_name FROM kingdom_members km JOIN accounts_profile ap ON km.user_id=ap.id WHERE km.kingdom_id=$1 ORDER BY km.rank", [kingdomId])).rows; }
  async join(kingdomId: string, userId: string, rank: string = "member") {
    await query("INSERT INTO kingdom_members (kingdom_id,user_id,rank) VALUES ($1,$2,$3) ON CONFLICT DO NOTHING", [kingdomId, userId, rank]);
    await query("UPDATE kingdom_registry SET member_count=member_count+1 WHERE id=$1", [kingdomId]);
  }
}
