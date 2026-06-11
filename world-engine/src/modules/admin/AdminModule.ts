import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class AdminModule extends WorldEngineModule {
  name = "AdminModule";
  override async initialize() { console.log("[AdminModule] Initialized — roles: owner, admin, moderator, staff"); }

  async grantZorium(targetUserId: string, characterId: string, amount: number, grantedBy: string) {
    await query("UPDATE wallets SET balance = balance + $1, updated_at = NOW() WHERE character_id = $2", [amount, characterId]);
    await query("UPDATE character_stats SET zorium = zorium + $1, updated_at = NOW() WHERE character_id = $2", [amount, characterId]);
    await query("INSERT INTO zorium_ledger (user_id, character_id, amount, tx_type, source, reason, created_by) VALUES ($1,$2,$3,'admin_grant','admin','Admin grant',$4)", [targetUserId, characterId, amount, grantedBy]);
    await query("INSERT INTO moderation_logs (staff_id, target_user_id, action, reason, metadata) VALUES ($1::uuid,$2,'grant_zorium','Admin grant',$3)", [grantedBy, targetUserId, JSON.stringify({amount, characterId})]);
    return { granted: amount };
  }
  async banUser(targetUserId: string, staffId: string, banType: string, reason: string, expiresAt?: string) {
    await query("INSERT INTO ban_records (user_id, staff_id, ban_type, reason, expires_at) VALUES ($1,$2,$3,$4,$5)", [targetUserId, staffId, banType, reason, expiresAt || null]);
    await query("UPDATE accounts_profile SET is_banned = true, status = 'banned' WHERE id = $1", [targetUserId]);
    await query("INSERT INTO moderation_logs (staff_id, target_user_id, action, reason) VALUES ($1::uuid,$2,$3,$4)", [staffId, targetUserId, 'ban_' + banType, reason]);
    return { banned: true };
  }
  async unbanUser(targetUserId: string, staffId: string) {
    await query("UPDATE ban_records SET is_active = false WHERE user_id = $1", [targetUserId]);
    await query("UPDATE accounts_profile SET is_banned = false, status = 'active' WHERE id = $1", [targetUserId]);
    await query("INSERT INTO moderation_logs (staff_id, target_user_id, action, reason) VALUES ($1::uuid,$2,'unban','Unbanned')", [staffId, targetUserId]);
    return { unbanned: true };
  }
  async announce(title: string, message: string, priority: number = 5, hoursActive: number = 24, createdBy: string = "system") {
    return (await query("INSERT INTO server_announcements (title, message, priority, expires_at, created_by) VALUES ($1,$2,$3,NOW()+($4||' hours')::interval,$5) RETURNING *", [title, message, priority, hoursActive, createdBy])).rows[0];
  }
  async getLoginHistory(userId: string, limit: number = 50) {
    return (await query("SELECT * FROM login_history WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2", [userId, limit])).rows;
  }
}
