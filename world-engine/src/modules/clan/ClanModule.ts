import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class ClanModule extends WorldEngineModule {
  name = "ClanModule";
  override async initialize() { console.log("[ClanModule] Initialized"); }

  async create(name: string, tag: string, leaderUserId: string, description: string = "") {
    const clan = (await query("INSERT INTO clans (name, tag, description, leader_user_id) VALUES ($1,$2,$3,$4) RETURNING *", [name, tag, description, leaderUserId])).rows[0];
    await query("INSERT INTO clan_members (clan_id, user_id, role) VALUES ($1,$2,'leader')", [clan.id, leaderUserId]);
    return clan;
  }
  async join(clanId: string, userId: string) {
    await query("INSERT INTO clan_members (clan_id, user_id, role) VALUES ($1,$2,'member') ON CONFLICT DO NOTHING", [clanId, userId]);
    await query("UPDATE clans SET member_count = member_count + 1 WHERE id = $1", [clanId]);
  }
  async leave(clanId: string, userId: string) {
    await query("DELETE FROM clan_members WHERE clan_id = $1 AND user_id = $2", [clanId, userId]);
    await query("UPDATE clans SET member_count = GREATEST(member_count - 1, 0) WHERE id = $1", [clanId]);
  }
  async getMembers(clanId: string) { return (await query("SELECT cm.*, ap.display_name FROM clan_members cm JOIN accounts_profile ap ON cm.user_id = ap.id WHERE cm.clan_id = $1 ORDER BY cm.role, cm.joined_at", [clanId])).rows; }
  async listClans() { return (await query("SELECT * FROM clans ORDER BY member_count DESC LIMIT 50")).rows; }
}
