import { WorldEngineModule } from "../../core/Module.js";
import { Entity } from "../../core/Entity.js";
import { query } from "../../db.js";

export class DragonModule extends WorldEngineModule {
  name = "DragonModule";

  override async initialize() {
    console.log("[DragonModule] Pronto para gerenciar dragoes");
  }

  async handleDragonSpawned(event: Awaited<ReturnType<typeof import("../../core/Event.js").GameEvent.findPending>>[number]) {
    const { source_entity_id, world_id, payload } = event;
    if (!source_entity_id) return;

    const dragon = await Entity.findById(source_entity_id);
    if (!dragon) {
      console.log(`[DragonModule] Dragao ${source_entity_id} nao encontrado`);
      return;
    }

    await Entity.updateState(source_entity_id, {
      alive: true,
      last_spawned: new Date().toISOString(),
      spawn_location: (payload as any)?.location || { x: dragon.position_x, y: dragon.position_y },
    });

    await query("UPDATE dragons SET is_alive = true, updated_at = NOW() WHERE entity_id = $1", [source_entity_id]);

    await query(
      "INSERT INTO audit_logs (actor_type, actor_id, action, target_type, target_id, payload) VALUES ($1,$2,$3,$4,$5,$6)",
      ["system", "dragon_module", "dragon_spawned", "dragon", source_entity_id, JSON.stringify(payload as Record<string, unknown>)]
    );

    console.log(`[DragonModule] Dragao ${dragon.name} spawnado no mundo ${world_id}`);
  }
}
