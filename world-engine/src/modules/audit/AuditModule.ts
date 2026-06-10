import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class AuditModule extends WorldEngineModule {
  name = "AuditModule";

  override async initialize() {
    console.log("[AuditModule] Pronto para auditoria");
  }

  async log(params: {
    actorType: string;
    actorId?: string;
    action: string;
    targetType?: string;
    targetId?: string;
    payload?: Record<string, unknown>;
  }) {
    await query(
      `INSERT INTO audit_logs (actor_type, actor_id, action, target_type, target_id, payload)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [params.actorType, params.actorId || null, params.action, params.targetType || null, params.targetId || null, JSON.stringify(params.payload || {})]
    );
    console.log(`[Audit] ${params.actorType}:${params.action}`);
  }
}
