import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class VIPModule extends WorldEngineModule {
  name = "VIPModule";
  override async initialize() { console.log("[VIPModule] Initialized — 20 VIP levels"); }

  async getLevels() {
    return (await query("SELECT * FROM vip_levels ORDER BY level")).rows;
  }
  async getUserVIP(userId: string) {
    return (await query("SELECT uv.*, vl.name, vl.badge, vl.color, vl.benefits FROM user_vip uv JOIN vip_levels vl ON uv.vip_level = vl.level WHERE uv.user_id = $1 AND uv.status = 'active' ORDER BY uv.vip_level DESC LIMIT 1", [userId])).rows[0] || null;
  }
  async grantVIP(userId: string, level: number, durationDays: number, grantedBy: string = "system") {
    return (await query("INSERT INTO user_vip (user_id, vip_level, expires_at, granted_by) VALUES ($1,$2,NOW()+($3||' days')::interval,$4) RETURNING *", [userId, level, durationDays, grantedBy])).rows[0];
  }
}
