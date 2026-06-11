import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class InventoryModule extends WorldEngineModule {
  name = "InventoryModule";
  static MAX_SLOTS = 20;

  override async initialize() {
    console.log("[InventoryModule] Initialized — max slots:", InventoryModule.MAX_SLOTS);
  }

  async getInventory(characterId: string) {
    const r = await query(
      `SELECT i.*, it.name as item_name, it.item_type, it.rarity, it.base_stats, it.description, it.slot_type
       FROM inventory i JOIN items it ON i.item_id = it.id
       WHERE i.character_id = $1 ORDER BY i.slot_index`, [characterId]
    );
    return r.rows;
  }

  async addItem(characterId: string, itemId: string, quantity: number = 1) {
    const existing = await query(
      "SELECT i.*, it.stackable, it.max_stack FROM inventory i JOIN items it ON i.item_id = it.id WHERE i.character_id = $1 AND i.item_id = $2",
      [characterId, itemId]
    );

    if (existing.rows.length > 0 && existing.rows[0].stackable) {
      const slot = existing.rows[0];
      const newQty = Math.min(slot.quantity + quantity, slot.max_stack);
      await query("UPDATE inventory SET quantity = $1, updated_at = NOW() WHERE id = $2", [newQty, slot.id]);
      return { action: "stacked", slotIndex: slot.slot_index, quantity: newQty };
    }

    const usedSlots = await query("SELECT slot_index FROM inventory WHERE character_id = $1", [characterId]);
    const used = new Set(usedSlots.rows.map((r: any) => r.slot_index));
    let freeSlot = -1;
    for (let s = 0; s < InventoryModule.MAX_SLOTS; s++) {
      if (!used.has(s)) { freeSlot = s; break; }
    }
    if (freeSlot === -1) return { action: "full", error: "Inventory full" };

    await query(
      "INSERT INTO inventory (character_id, item_id, slot_index, quantity) VALUES ($1,$2,$3,$4)",
      [characterId, itemId, freeSlot, quantity]
    );
    return { action: "added", slotIndex: freeSlot, quantity };
  }

  async removeItem(characterId: string, slotIndex: number) {
    await query("DELETE FROM inventory WHERE character_id = $1 AND slot_index = $2", [characterId, slotIndex]);
  }
}
