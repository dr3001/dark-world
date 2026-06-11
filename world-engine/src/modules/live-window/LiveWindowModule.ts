import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class LiveWindowModule extends WorldEngineModule {
  name = "LiveWindowModule";
  override async initialize() { console.log("[LiveWindowModule] Initialized — billing ready"); }

  async getProducts() { return (await query("SELECT * FROM live_window_products")).rows; }
  async createWindow(userId: string, productId: string) {
    const product = (await query("SELECT * FROM live_window_products WHERE id=$1", [productId])).rows[0];
    if (!product) return { error: "Product not found" };
    const starts = new Date().toISOString();
    const ends = new Date(Date.now() + product.duration_minutes * 60000).toISOString();
    const r = await query("INSERT INTO live_windows (user_id, window_type, status, starts_at, ends_at, duration_minutes, max_streams, max_ai_minutes, max_transcription_minutes) VALUES ($1,$2,'pending_payment',$3,$4,$5,$6,$7,$8) RETURNING *", [userId, product.window_type, starts, ends, product.duration_minutes, product.max_streams, 60, 30]);
    return { window: r.rows[0], mode: process.env.STRIPE_SECRET_KEY ? "live" : "sandbox" };
  }
  async getUserWindows(userId: string) {
    return (await query("SELECT * FROM live_windows WHERE user_id=$1 ORDER BY created_at DESC", [userId])).rows;
  }
  async activateWindow(windowId: string) {
    await query("UPDATE live_windows SET status='active' WHERE id=$1 AND status='pending_payment'", [windowId]);
  }
}
