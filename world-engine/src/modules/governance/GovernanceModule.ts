import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class GovernanceModule extends WorldEngineModule {
  name = "GovernanceModule";
  override async initialize() { console.log("[Governance] Initialized — terms, KYC, violations, forum, tickets"); }

  async acceptTerms(userId: string, ip: string, deviceId: string = "") {
    const v = await query("SELECT * FROM terms_acceptance WHERE user_id = $1 AND terms_version = '1.0.0'", [userId]);
    if (v.rows[0]) return { already_accepted: true };
    await query("INSERT INTO terms_acceptance (user_id, terms_version, privacy_version, ip, device_id) VALUES ($1,'1.0.0','1.0.0',$2,$3)", [userId, ip, deviceId]);
    return { accepted: true };
  }

  async getTermsStatus(userId: string) {
    const r = await query("SELECT * FROM terms_acceptance WHERE user_id = $1 ORDER BY accepted_at DESC LIMIT 1", [userId]);
    return { accepted: r.rows.length > 0, terms: r.rows[0] || null };
  }

  async updateKYC(userId: string, data: Record<string, unknown>) {
    const allowed = ["phone", "birthdate", "city", "state", "country"];
    for (const k of allowed) {
      if (data[k] !== undefined) await query(`UPDATE accounts_profile SET ${k} = $1 WHERE id = $2`, [data[k], userId]);
    }
    return { updated: true };
  }

  async getViolations() { return (await query("SELECT * FROM violation_catalog ORDER BY category, severity")).rows; }

  async banUser(targetId: string, staffId: string, banType: string, reason: string, violationType: string = "", isPermanent: boolean = false) {
    await query("INSERT INTO ban_records (user_id, staff_id, ban_type, reason, violation_type, owner_only) VALUES ($1,$2,$3,$4,$5,$6)", [targetId, staffId, banType, reason, violationType, isPermanent]);
    await query("UPDATE accounts_profile SET is_banned = true, status = 'banned' WHERE id = $1", [targetId]);
    await query("INSERT INTO moderation_logs (staff_id, target_user_id, action, reason) VALUES ($1::uuid,$2,$3,$4)", [staffId, targetId, 'ban_' + banType, reason]);
    return { banned: true };
  }

  async unbanUser(targetId: string, staffId: string) {
    const staff = (await query("SELECT role FROM accounts_profile WHERE id = $1", [staffId])).rows[0];
    const bans = (await query("SELECT * FROM ban_records WHERE user_id = $1 AND is_active = true AND owner_only = true", [targetId])).rows;
    if (bans.length > 0 && staff?.role !== "owner") return { error: "Only OWNER can remove permanent bans. Contact Rogério." };
    await query("UPDATE ban_records SET is_active = false WHERE user_id = $1", [targetId]);
    await query("UPDATE accounts_profile SET is_banned = false, status = 'active' WHERE id = $1", [targetId]);
    await query("INSERT INTO moderation_logs (staff_id, target_user_id, action, reason) VALUES ($1::uuid,$2,'unban','Unbanned')", [staffId, targetId]);
    return { unbanned: true };
  }
}
