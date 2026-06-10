import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class TerritoryModule extends WorldEngineModule {
  name = "TerritoryModule";

  override async initialize() {
    console.log("[TerritoryModule] Pronto para gerenciar territórios");
  }

  async handleTerritoryClaimed(event: Awaited<ReturnType<typeof import("../../core/Event.js").GameEvent.findPending>>[number]) {
    const { target_entity_id, payload } = event;
    if (!target_entity_id) return;

    const factionId = (payload as any)?.faction_id;
    if (!factionId) return;

    await query("UPDATE territories SET controlled_by_faction_id = $1, updated_at = NOW() WHERE entity_id = $2", [factionId, target_entity_id]);

    console.log(`[TerritoryModule] Território ${target_entity_id} reivindicado por ${factionId}`);
  }
}
