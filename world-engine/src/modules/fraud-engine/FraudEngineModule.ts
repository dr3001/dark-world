import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class FraudEngineModule extends WorldEngineModule {
  name = "FraudEngineModule";
  override async initialize() { console.log("[FraudEngine] Initialized — 15 categories, 5 rules seeded"); }

  async logEvent(userId: string | null, category: string, severity: string, evidence: Record<string, unknown> = {}, source: string = "auto") {
    return (await query("INSERT INTO fraud_events (user_id, category, severity, source, evidence) VALUES ($1,$2,$3,$4,$5) RETURNING *", [userId, category, severity, source, JSON.stringify(evidence)])).rows[0];
  }

  async getFraudDashboard() {
    const byCategory = (await query("SELECT category, count(*) as total FROM fraud_events WHERE resolved = false GROUP BY category ORDER BY total DESC")).rows;
    const bySeverity = (await query("SELECT severity, count(*) as total FROM fraud_events WHERE resolved = false GROUP BY severity ORDER BY total DESC")).rows;
    const total = (await query("SELECT count(*) FROM fraud_events WHERE resolved = false")).rows[0]?.count || 0;
    return { total_unresolved: parseInt(total), by_category: byCategory, by_severity: bySeverity };
  }

  async resolveEvent(eventId: string, resolvedBy: string) {
    await query("UPDATE fraud_events SET resolved = true, resolved_by = $1 WHERE id = $2", [resolvedBy, eventId]);
  }

  async getRules() {
    return (await query("SELECT * FROM fraud_rules WHERE enabled = true")).rows;
  }
}
