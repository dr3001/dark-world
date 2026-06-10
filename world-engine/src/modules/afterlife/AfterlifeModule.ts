import { WorldEngineModule } from "../../core/Module.js";
import { Entity } from "../../core/Entity.js";
import { GameEvent } from "../../core/Event.js";
import { query } from "../../db.js";
import { KNOWN_UUIDS } from "../../config.js";

export class AfterlifeModule extends WorldEngineModule {
  name = "AfterlifeModule";

  override async initialize() {
    console.log("[AfterlifeModule] Pronto para processar afterlife");
  }

  async handleAfterlifeEntered(event: Awaited<ReturnType<typeof GameEvent.findPending>>[number]) {
    const { target_entity_id, payload } = event;
    if (!target_entity_id) return;

    const entity = await Entity.findById(target_entity_id);
    if (!entity) return;

    await Entity.updateWorld(target_entity_id, KNOWN_UUIDS.WORLD_FROZEN);
    await Entity.updateState(target_entity_id, {
      ...(entity.state as Record<string, unknown>),
      afterlife: true,
      entered_at: new Date().toISOString(),
      eligible_return_at: (payload as any)?.eligible_return_at,
    });

    await query("UPDATE characters SET life_state = 'afterlife', updated_at = NOW() WHERE entity_id = $1", [target_entity_id]);

    await query(
      "INSERT INTO afterlife_records (character_id, death_event_id, from_world_id, afterlife_world_id, eligible_return_at, state) VALUES ((SELECT id FROM characters WHERE entity_id = $1), $2, $3, $4, $5, $6)",
      [target_entity_id, event.id, entity.world_id, KNOWN_UUIDS.WORLD_FROZEN, (payload as any)?.eligible_return_at, JSON.stringify({ auto_return: true })]
    );

    await query(
      "INSERT INTO audit_logs (actor_type, actor_id, action, target_type, target_id, payload) VALUES ($1,$2,$3,$4,$5,$6)",
      ["system", "afterlife_module", "afterlife_entered", "character", target_entity_id, JSON.stringify({ to_world: KNOWN_UUIDS.WORLD_FROZEN })]
    );

    console.log(`[AfterlifeModule] Entidade ${target_entity_id} enviada para Mundo Congelado`);
  }

  async handleAfterlifeReturned(event: Awaited<ReturnType<typeof GameEvent.findPending>>[number]) {
    const { target_entity_id } = event;
    if (!target_entity_id) return;

    const entity = await Entity.findById(target_entity_id);
    if (!entity) return;

    await Entity.updateWorld(target_entity_id, KNOWN_UUIDS.WORLD_LIVING);
    await Entity.setStatus(target_entity_id, "active");
    await Entity.updateState(target_entity_id, { afterlife: false, returned_at: new Date().toISOString() });

    await query("UPDATE characters SET life_state = 'returned', updated_at = NOW() WHERE entity_id = $1", [target_entity_id]);

    await query("UPDATE afterlife_records SET returned_at = NOW() WHERE character_id = (SELECT id FROM characters WHERE entity_id = $1) AND returned_at IS NULL", [target_entity_id]);

    await query(
      "INSERT INTO audit_logs (actor_type, actor_id, action, target_type, target_id, payload) VALUES ($1,$2,$3,$4,$5,$6)",
      ["system", "afterlife_module", "afterlife_returned", "character", target_entity_id, JSON.stringify({ from_world: KNOWN_UUIDS.WORLD_FROZEN })]
    );

    console.log(`[AfterlifeModule] Entidade ${target_entity_id} retornou dos mortos!`);
  }
}
