import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class ItemModule extends WorldEngineModule {
  name = "ItemModule";

  override async initialize() {
    console.log("[ItemModule] Initialized");
  }

  async getAll() {
    const r = await query("SELECT * FROM items ORDER BY rarity, name");
    return r.rows;
  }

  async getById(itemId: string) {
    const r = await query("SELECT * FROM items WHERE id = $1", [itemId]);
    return r.rows[0] || null;
  }

  async getByType(itemType: string) {
    const r = await query("SELECT * FROM items WHERE item_type = $1 ORDER BY rarity, name", [itemType]);
    return r.rows;
  }

  async create(data: { name: string; itemType: string; rarity?: string; slotType?: string; baseStats?: Record<string, number>; description?: string; stackable?: boolean; maxStack?: number; valueZorium?: number }) {
    const r = await query(
      `INSERT INTO items (name, item_type, rarity, slot_type, base_stats, description, stackable, max_stack, value_zorium)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
      [data.name, data.itemType, data.rarity || "common", data.slotType || null, JSON.stringify(data.baseStats || {}), data.description || "", data.stackable || false, data.maxStack || 1, data.valueZorium || 0]
    );
    return r.rows[0];
  }
}
