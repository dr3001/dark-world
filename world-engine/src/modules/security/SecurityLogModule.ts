import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class SecurityLogModule extends WorldEngineModule {
  name = "SecurityLogModule";
  override async initialize() { console.log("[SecurityLogModule] Initialized — risk levels: low, medium, high, critical"); }

  async log(userId: string | null, action: string, ip: string | null, riskLevel: string = "low", metadata: Record<string, unknown> = {}) {
    await query("INSERT INTO security_logs (user_id, action, ip, risk_level, metadata) VALUES ($1,$2,$3,$4,$5)", [userId, action, ip, riskLevel, JSON.stringify(metadata)]);
  }
  async getRecent(limit: number = 50) {
    return (await query("SELECT sl.*, ap.display_name FROM security_logs sl LEFT JOIN accounts_profile ap ON sl.user_id=ap.id ORDER BY sl.created_at DESC LIMIT $1", [limit])).rows;
  }
  async getByRisk(riskLevel: string, limit: number = 50) {
    return (await query("SELECT * FROM security_logs WHERE risk_level=$1 ORDER BY created_at DESC LIMIT $2", [riskLevel, limit])).rows;
  }
}
