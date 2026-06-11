import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class TwitchModule extends WorldEngineModule {
  name = "TwitchModule";
  override async initialize() { console.log("[TwitchModule] Initialized — OAuth + EventSub ready"); }

  async linkAccount(userId: string, twitchUserId: string, twitchLogin: string, displayName: string, accessToken: string, refreshToken: string, scopes: string[], expiresIn: number) {
    const expires = new Date(Date.now() + expiresIn * 1000).toISOString();
    await query("INSERT INTO twitch_account_links (user_id, twitch_user_id, twitch_login, twitch_display_name, access_token_encrypted, refresh_token_encrypted, scopes, expires_at) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT (user_id) DO UPDATE SET access_token_encrypted=$5, refresh_token_encrypted=$6, scopes=$7, expires_at=$8, status='active'", [userId, twitchUserId, twitchLogin, displayName, accessToken, refreshToken, scopes, expires]);
    return { linked: true };
  }
  async getLinked(userId: string) {
    const r = await query("SELECT twitch_user_id, twitch_login, twitch_display_name, scopes, expires_at, status FROM twitch_account_links WHERE user_id = $1", [userId]);
    if (!r.rows[0]) return { linked: false, mode: process.env.TWITCH_CLIENT_ID ? "oauth_ready" : "not_configured" };
    return { linked: true, ...r.rows[0], scopes: r.rows[0].scopes || [] };
  }
  async createOverlay(userId: string, sceneType: string) {
    const token = require("crypto").randomBytes(16).toString("hex");
    const r = await query("INSERT INTO streamer_overlays (user_id, overlay_token, scene_type) VALUES ($1,$2,$3) RETURNING *", [userId, token, sceneType]);
    return r.rows[0];
  }
  async getOverlay(token: string) {
    return (await query("SELECT so.*, ow.* FROM streamer_overlays so LEFT JOIN overlay_widgets ow ON ow.overlay_id = so.id WHERE so.overlay_token = $1 AND so.is_active = true", [token])).rows;
  }
}
