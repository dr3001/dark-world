import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class TrustEngineModule extends WorldEngineModule {
  name = "TrustEngineModule";
  override async initialize() { console.log("[TrustEngine] Initialized — 0-1000 trust score"); }

  async getProfile(userId: string) {
    await query("INSERT INTO trust_profiles (user_id, trust_score) VALUES ($1, 500) ON CONFLICT DO NOTHING", [userId]);
    return (await query("SELECT * FROM trust_profiles WHERE user_id = $1", [userId])).rows[0];
  }

  async addEvent(userId: string, eventType: string, scoreDelta: number, reason: string) {
    const profile = await this.getProfile(userId);
    const oldScore = parseInt(profile.trust_score);
    const newScore = Math.max(0, Math.min(1000, oldScore + scoreDelta));
    await query("UPDATE trust_profiles SET trust_score = $1, updated_at = NOW() WHERE user_id = $2", [newScore, userId]);
    await query("INSERT INTO trust_events (user_id, event_type, score_delta, old_score, new_score, reason) VALUES ($1,$2,$3,$4,$5,$6)", [userId, eventType, scoreDelta, oldScore, newScore, reason]);
    await query("UPDATE trust_profiles SET device_changes = COALESCE(device_changes,0)+1 WHERE user_id = $1 AND $2 = 'device_change'", [userId, eventType]);
    if (eventType === "login_failed") await query("UPDATE trust_profiles SET login_failures = login_failures + 1 WHERE user_id = $1", [userId]);
    if (eventType === "fraud_detected") await query("UPDATE trust_profiles SET fraud_flags = fraud_flags + 1 WHERE user_id = $1", [userId]);
    return { oldScore, newScore, delta: scoreDelta };
  }

  async registerDevice(userId: string, deviceData: Record<string, unknown>) {
    const instId = (deviceData.installation_id as string) || "unknown";
    const hash = (deviceData.device_id_hash as string) || "unknown";
    const existing = await query("SELECT * FROM device_profiles WHERE installation_id = $1", [instId]);
    if (existing.rows[0]) {
      await query("UPDATE device_profiles SET last_seen = NOW(), ip_last = $1 WHERE id = $2", [deviceData.ip || null, existing.rows[0].id]);
      return existing.rows[0];
    }
    const r = await query(
      "INSERT INTO device_profiles (user_id, installation_id, device_id_hash, os_name, ip_first, ip_last) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *",
      [userId, instId, hash, deviceData.os || "unknown", deviceData.ip || null, deviceData.ip || null]
    );
    await this.addEvent(userId, "device_registered", 0, "First device registered");
    return r.rows[0];
  }

  async getTopLowTrust(limit: number = 10) {
    return (await query("SELECT tp.*, ap.display_name, ap.email FROM trust_profiles tp JOIN accounts_profile ap ON tp.user_id = ap.id WHERE tp.trust_score < 300 ORDER BY tp.trust_score ASC LIMIT $1", [limit])).rows;
  }

  async getDashboard() {
    const avg = (await query("SELECT AVG(trust_score)::int as avg FROM trust_profiles")).rows[0]?.avg || 500;
    const low = (await query("SELECT count(*) FROM trust_profiles WHERE trust_score < 300")).rows[0]?.count || 0;
    const high = (await query("SELECT count(*) FROM trust_profiles WHERE trust_score > 800")).rows[0]?.count || 0;
    return { avg_trust: avg, low_trust_count: parseInt(low), high_trust_count: parseInt(high) };
  }
}
