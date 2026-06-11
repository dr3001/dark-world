import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class ChatModule extends WorldEngineModule {
  name = "ChatModule";
  override async initialize() { console.log("[ChatModule] Initialized — channels: global, local, clan, system, staff"); }

  async sendMessage(userId: string, characterId: string | null, displayName: string, message: string, channel: string = "global", vipLevel: number = 0, role: string = "player") {
    return (await query("INSERT INTO chat_messages (user_id, character_id, display_name, vip_level, role, message, channel) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *", [userId, characterId, displayName, vipLevel, role, message, channel])).rows[0];
  }
  async getRecent(channel: string = "global", limit: number = 30) {
    return (await query("SELECT * FROM chat_messages WHERE channel = $1 AND moderation_status = 'ok' ORDER BY created_at DESC LIMIT $2", [channel, limit])).rows.reverse();
  }
  async flagMessage(messageId: string) {
    await query("UPDATE chat_messages SET moderation_status = 'flagged' WHERE id = $1", [messageId]);
  }
  async deleteMessage(messageId: string) {
    await query("UPDATE chat_messages SET moderation_status = 'deleted' WHERE id = $1", [messageId]);
  }
}
