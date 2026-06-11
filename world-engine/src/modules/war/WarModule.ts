import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class WarModule extends WorldEngineModule {
  name = "WarModule";
  override async initialize() { console.log("[WarModule] Initialized — war declarations ready"); }
  async declare(attackerType: string, attackerId: string, defenderType: string, defenderId: string, declaredBy: string, reason: string = "") {
    const r = await query("INSERT INTO war_declarations (attacker_type,attacker_id,defender_type,defender_id,declared_by,reason) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *", [attackerType, attackerId, defenderType, defenderId, declaredBy, reason]);
    await query("INSERT INTO war_logs (war_id,actor_id,action,details) VALUES ($1,$2,'declared',$3)", [r.rows[0].id, declaredBy, JSON.stringify({reason})]);
    return r.rows[0];
  }
  async getById(warId: string) { return (await query("SELECT * FROM war_declarations WHERE id = $1", [warId])).rows[0]; }
  async getActive() { return (await query("SELECT * FROM war_declarations WHERE state IN ('declared','preparation','active') ORDER BY created_at DESC")).rows; }
  async getParticipants(warId: string) { return (await query("SELECT wp.*,c.character_name FROM war_participants wp JOIN characters c ON wp.character_id=c.id WHERE wp.war_id=$1", [warId])).rows; }
  async updateState(warId: string, state: string, actorId: string) {
    await query("UPDATE war_declarations SET state=$1 WHERE id=$2", [state, warId]);
    await query("INSERT INTO war_logs (war_id,actor_id,action) VALUES ($1,$2,$3)", [warId, actorId, "state_" + state]);
  }
}
