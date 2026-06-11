import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";
import { KNOWN_UUIDS } from "../../config.js";

export class MultiplayerModule extends WorldEngineModule {
  name = "MultiplayerModule";
  override async initialize() { console.log("[MultiplayerModule] Initialized — REST polling mode"); }

  async reportPosition(characterId: string, userId: string, x: number, y: number, z: number, displayName: string, vipLevel: number = 0, role: string = "player") {
    await query(
      `INSERT INTO player_positions (character_id, user_id, world_id, x, y, z, display_name, vip_level, role, updated_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,NOW())
       ON CONFLICT (character_id) DO UPDATE SET x=$4, y=$5, z=$6, display_name=$7, vip_level=$8, role=$9, updated_at=NOW()`,
      [characterId, userId, KNOWN_UUIDS.WORLD_LIVING, x, y, z, displayName, vipLevel, role]
    );
    await query(
      "INSERT INTO online_sessions (character_id, user_id, last_heartbeat, is_online) VALUES ($1,$2,NOW(),true) ON CONFLICT (character_id) DO UPDATE SET last_heartbeat=NOW(), is_online=true",
      [characterId, userId]
    );
  }

  async getNearby(worldId?: string) {
    const cutoff = "NOW() - INTERVAL '10 seconds'";
    return (await query(
      `SELECT pp.character_id, pp.display_name, pp.x, pp.y, pp.z, pp.vip_level, pp.role
       FROM player_positions pp
       JOIN online_sessions os ON pp.character_id = os.character_id
       WHERE os.is_online = true AND os.last_heartbeat > ${cutoff}
       ORDER BY pp.updated_at DESC LIMIT 50`
    )).rows;
  }

  async getOnlineCount() {
    const r = await query("SELECT count(*) FROM online_sessions WHERE is_online = true AND last_heartbeat > NOW() - INTERVAL '10 seconds'");
    return parseInt(r.rows[0].count);
  }

  async heartbeat(characterId: string) {
    await query("UPDATE online_sessions SET last_heartbeat = NOW(), is_online = true WHERE character_id = $1", [characterId]);
  }

  async markOffline(characterId: string) {
    await query("UPDATE online_sessions SET is_online = false WHERE character_id = $1", [characterId]);
  }
}
