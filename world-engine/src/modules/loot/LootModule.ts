import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class LootModule extends WorldEngineModule {
  name = "LootModule";

  override async initialize() {
    console.log("[LootModule] Initialized");
  }

  async getDropTable(sourceType: string, sourceId: string) {
    const r = await query(
      `SELECT lt.*, i.name as item_name, i.item_type, i.rarity, i.base_stats, i.description
       FROM loot_tables lt JOIN items i ON lt.item_id = i.id
       WHERE lt.source_type = $1 AND lt.source_id = $2`, [sourceType, sourceId]
    );
    return r.rows;
  }

  async rollLoot(sourceType: string, sourceId: string): Promise<Array<{ itemId: string; itemName: string; quantity: number }>> {
    const table = await this.getDropTable(sourceType, sourceId);
    const drops: Array<{ itemId: string; itemName: string; quantity: number }> = [];
    for (const entry of table) {
      const chance = parseFloat(entry.drop_chance);
      if (Math.random() <= chance) {
        const minQ = entry.min_qty;
        const maxQ = entry.max_qty;
        const qty = minQ + Math.floor(Math.random() * (maxQ - minQ + 1));
        drops.push({ itemId: entry.item_id, itemName: entry.item_name, quantity: qty });
      }
    }
    return drops;
  }
}
