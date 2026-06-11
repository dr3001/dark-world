import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class EventModule extends WorldEngineModule {
  name = "EventModule";
  override async initialize() { console.log("[EventModule] Initialized — seasonal events ready"); }

  async getActive() { return (await query("SELECT * FROM game_events WHERE status = 'active' ORDER BY starts_at")).rows; }
  async getScheduled() { return (await query("SELECT * FROM game_events WHERE status IN ('scheduled','active') ORDER BY starts_at")).rows; }
  async getCalendar() {
    const events = (await query("SELECT id, name, event_type, starts_at, ends_at, status FROM game_events ORDER BY starts_at")).rows;
    const maintenance = (await query("SELECT id, title, starts_at, ends_at, status FROM scheduled_maintenance WHERE status IN ('scheduled','active') ORDER BY starts_at")).rows;
    const announcements = (await query("SELECT id, title, message, priority, expires_at FROM server_announcements WHERE expires_at > NOW() ORDER BY priority DESC")).rows;
    return { events, maintenance, announcements };
  }
  async activateEvent(eventId: string) { await query("UPDATE game_events SET status = 'active' WHERE id = $1", [eventId]); }
  async endEvent(eventId: string) { await query("UPDATE game_events SET status = 'ended' WHERE id = $1", [eventId]); }
}
