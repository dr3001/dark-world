import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class StoreModule extends WorldEngineModule {
  name = "StoreModule";
  override async initialize() { console.log("[StoreModule] Initialized — sandbox mode"); }

  async getCategories() { return (await query("SELECT * FROM store_categories WHERE is_active = true ORDER BY sort_order")).rows; }
  async getProducts(categorySlug?: string) {
    if (categorySlug) return (await query("SELECT p.*, c.name as category_name FROM store_products p JOIN store_categories c ON p.category_id = c.id WHERE c.slug = $1 ORDER BY p.name", [categorySlug])).rows;
    return (await query("SELECT p.*, c.name as category_name FROM store_products p JOIN store_categories c ON p.category_id = c.id ORDER BY c.sort_order, p.name")).rows;
  }
  async createPurchase(userId: string, productId: string, amountPaid: number, currency: string = "BRL") {
    return (await query("INSERT INTO store_purchases (user_id, product_id, amount_paid, currency, status) VALUES ($1,$2,$3,$4,'pending') RETURNING *", [userId, productId, amountPaid, currency])).rows[0];
  }
  async confirmPurchase(purchaseId: string) {
    return (await query("UPDATE store_purchases SET status = 'confirmed', delivered = true WHERE id = $1 RETURNING *", [purchaseId])).rows[0];
  }
}
