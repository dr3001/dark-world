import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class EquipmentModule extends WorldEngineModule {
  name = "EquipmentModule";

  override async initialize() {
    console.log("[EquipmentModule] Initialized");
  }

  async getEquipment(characterId: string) {
    const r = await query(
      `SELECT e.*, i.name as item_name, i.item_type, i.rarity, i.base_stats, i.slot_type as item_slot_type
       FROM equipment e JOIN items i ON e.item_id = i.id
       WHERE e.character_id = $1`, [characterId]
    );
    return r.rows;
  }

  async equip(characterId: string, itemId: string, slotType: string) {
    const item = await query("SELECT * FROM items WHERE id = $1", [itemId]);
    if (!item.rows[0]) return { error: "Item not found" };
    if (item.rows[0].slot_type && item.rows[0].slot_type !== slotType) {
      return { error: "Item cannot be equipped in this slot" };
    }

    const existing = await query("SELECT * FROM equipment WHERE character_id = $1 AND slot_type = $2", [characterId, slotType]);
    if (existing.rows[0]) {
      await query("UPDATE equipment SET item_id = $1, created_at = NOW() WHERE character_id = $2 AND slot_type = $3", [itemId, characterId, slotType]);
      return { action: "replaced", previousItemId: existing.rows[0].item_id };
    }

    await query("INSERT INTO equipment (character_id, slot_type, item_id) VALUES ($1,$2,$3)", [characterId, slotType, itemId]);
    return { action: "equipped" };
  }

  async unequip(characterId: string, slotType: string) {
    const r = await query("DELETE FROM equipment WHERE character_id = $1 AND slot_type = $2 RETURNING *", [characterId, slotType]);
    if (!r.rows[0]) return { error: "Nothing equipped in this slot" };
    return { action: "unequipped", itemId: r.rows[0].item_id };
  }

  async getStatBonuses(characterId: string) {
    const equips = await this.getEquipment(characterId);
    const bonuses: Record<string, number> = {};
    for (const eq of equips) {
      const stats = typeof eq.base_stats === "string" ? JSON.parse(eq.base_stats) : eq.base_stats;
      for (const [k, v] of Object.entries(stats)) {
        bonuses[k] = (bonuses[k] || 0) + (v as number);
      }
    }
    return bonuses;
  }
}
