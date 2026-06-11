import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class FriendsModule extends WorldEngineModule {
  name = "FriendsModule";
  override async initialize() { console.log("[FriendsModule] Initialized"); }

  async sendRequest(fromUserId: string, toUserId: string) {
    const existing = await query("SELECT * FROM friend_requests WHERE from_user_id=$1 AND to_user_id=$2 AND status='pending'", [fromUserId, toUserId]);
    if (existing.rows[0]) return { error: "Request already pending" };
    const blocked = await query("SELECT * FROM friends WHERE user_id=$1 AND friend_id=$2 AND status='blocked'", [toUserId, fromUserId]);
    if (blocked.rows[0]) return { error: "Cannot send request" };
    return (await query("INSERT INTO friend_requests (from_user_id, to_user_id) VALUES ($1,$2) ON CONFLICT DO NOTHING RETURNING *", [fromUserId, toUserId])).rows[0];
  }
  async acceptRequest(requestId: string, userId: string) {
    const req = (await query("UPDATE friend_requests SET status='accepted' WHERE id=$1 AND to_user_id=$2 AND status='pending' RETURNING *", [requestId, userId])).rows[0];
    if (!req) return { error: "Request not found" };
    await query("INSERT INTO friends (user_id, friend_id) VALUES ($1,$2),($2,$1) ON CONFLICT DO NOTHING", [req.from_user_id, req.to_user_id]);
    return { accepted: true };
  }
  async removeFriend(userId: string, friendId: string) {
    await query("DELETE FROM friends WHERE (user_id=$1 AND friend_id=$2) OR (user_id=$2 AND friend_id=$1)", [userId, friendId]);
    return { removed: true };
  }
  async blockUser(userId: string, targetId: string) {
    await query("DELETE FROM friends WHERE (user_id=$1 AND friend_id=$2) OR (user_id=$2 AND friend_id=$1)", [userId, targetId]);
    await query("INSERT INTO friends (user_id, friend_id, status) VALUES ($1,$2,'blocked') ON CONFLICT (user_id, friend_id) DO UPDATE SET status='blocked'", [userId, targetId]);
    return { blocked: true };
  }
  async listFriends(userId: string) {
    return (await query("SELECT f.friend_id, ap.display_name, ap.role, ap.vip_level FROM friends f JOIN accounts_profile ap ON f.friend_id=ap.id WHERE f.user_id=$1 AND f.status='active'", [userId])).rows;
  }
  async listRequests(userId: string) {
    return (await query("SELECT fr.*, ap.display_name FROM friend_requests fr JOIN accounts_profile ap ON fr.from_user_id=ap.id WHERE fr.to_user_id=$1 AND fr.status='pending'", [userId])).rows;
  }
}
