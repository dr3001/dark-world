import { WorldEngineModule } from "../../core/Module.js";
import { Entity } from "../../core/Entity.js";
import { GameEvent } from "../../core/Event.js";
import { query } from "../../db.js";
import { config, KNOWN_UUIDS } from "../../config.js";

export class DeathModule extends WorldEngineModule {
  name = "DeathModule";

  override async initialize() {
    console.log("[DeathModule] Pronto para processar mortes");
  }

  async handleDeath(event: Awaited<ReturnType<typeof GameEvent.findPending>>[number]) {
    const { target_entity_id, world_id, payload } = event;
    if (!target_entity_id) return;

    const entity = await Entity.findById(target_entity_id);
    if (!entity) {
      console.log(`[DeathModule] Entidade ${target_entity_id} nao encontrada`);
      return;
    }

    await query(
      "UPDATE characters SET life_state = 'dead', updated_at = NOW() WHERE entity_id = $1",
      [target_entity_id]
    );

    await query(
      "INSERT INTO deaths (character_id, killed_by_entity_id, world_id, death_location, died_at) VALUES ((SELECT id FROM characters WHERE entity_id = $1), $2, $3, $4, NOW())",
      [target_entity_id, event.source_entity_id ?? null, world_id, JSON.stringify({ x: entity.position_x, y: entity.position_y })]
    );

    await Entity.setStatus(target_entity_id, "dead");

    const eligibleReturn = new Date();
    eligibleReturn.setMinutes(eligibleReturn.getMinutes() + config.afterlife.testMinutes);

    await GameEvent.create({
      eventType: "AFTERLIFE_ENTERED",
      targetEntityId: target_entity_id,
      worldId: world_id ?? undefined,
      payload: {
        reason: (payload as any)?.reason || "unknown",
        from_world: world_id,
        to_world: KNOWN_UUIDS.WORLD_FROZEN,
        eligible_return_at: eligibleReturn.toISOString(),
      },
    });

    await query(
      "INSERT INTO audit_logs (actor_type, actor_id, action, target_type, target_id, payload) VALUES ($1,$2,$3,$4,$5,$6)",
      ["system", "death_module", "character_died", "character", target_entity_id, JSON.stringify({ reason: (payload as any)?.reason })]
    );

    console.log(`[DeathModule] Personagem ${target_entity_id} morreu. Indo para afterlife.`);
  }
}
