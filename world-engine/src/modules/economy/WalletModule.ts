import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class WalletModule extends WorldEngineModule {
  name = "WalletModule";

  override async initialize() {
    console.log("[WalletModule] Initialized — currency: ZORIUM");
  }

  async ensureWallet(characterId: string) {
    const existing = await query("SELECT * FROM wallets WHERE character_id = $1", [characterId]);
    if (existing.rows[0]) return existing.rows[0];
    const r = await query("INSERT INTO wallets (character_id, balance) VALUES ($1, 0) ON CONFLICT (character_id) DO NOTHING RETURNING *", [characterId]);
    return r.rows[0] || (await query("SELECT * FROM wallets WHERE character_id = $1", [characterId])).rows[0];
  }

  async getBalance(characterId: string) {
    const w = await this.ensureWallet(characterId);
    return { characterId, balance: parseFloat(w.balance) };
  }

  async credit(characterId: string, amount: number, txType: string, description: string = "") {
    const w = await this.ensureWallet(characterId);
    await query("UPDATE wallets SET balance = balance + $1, updated_at = NOW() WHERE id = $2", [amount, w.id]);
    await query(
      "INSERT INTO transactions (to_wallet_id, amount, tx_type, description) VALUES ($1,$2,$3,$4)",
      [w.id, amount, txType, description]
    );
    await query("UPDATE character_stats SET zorium = zorium + $1, updated_at = NOW() WHERE character_id = $2", [amount, characterId]);
    return { balance: parseFloat(w.balance) + amount };
  }

  async debit(characterId: string, amount: number, txType: string, description: string = "") {
    const w = await this.ensureWallet(characterId);
    if (parseFloat(w.balance) < amount) return { error: "Insufficient zorium" };
    await query("UPDATE wallets SET balance = balance - $1, updated_at = NOW() WHERE id = $2", [amount, w.id]);
    await query(
      "INSERT INTO transactions (from_wallet_id, amount, tx_type, description) VALUES ($1,$2,$3,$4)",
      [w.id, amount, txType, description]
    );
    await query("UPDATE character_stats SET zorium = zorium - $1, updated_at = NOW() WHERE character_id = $2", [amount, characterId]);
    return { balance: parseFloat(w.balance) - amount };
  }

  async transfer(fromCharacterId: string, toCharacterId: string, amount: number, description: string = "") {
    const from = await this.ensureWallet(fromCharacterId);
    const to = await this.ensureWallet(toCharacterId);
    if (parseFloat(from.balance) < amount) return { error: "Insufficient zorium" };
    await query("UPDATE wallets SET balance = balance - $1, updated_at = NOW() WHERE id = $2", [amount, from.id]);
    await query("UPDATE wallets SET balance = balance + $1, updated_at = NOW() WHERE id = $2", [amount, to.id]);
    await query(
      "INSERT INTO transactions (from_wallet_id, to_wallet_id, amount, tx_type, description) VALUES ($1,$2,$3,'trade',$4)",
      [from.id, to.id, amount, description]
    );
    return { fromBalance: parseFloat(from.balance) - amount, toBalance: parseFloat(to.balance) + amount };
  }

  async getHistory(characterId: string, limit: number = 20) {
    const w = await this.ensureWallet(characterId);
    const r = await query(
      "SELECT * FROM transactions WHERE from_wallet_id = $1 OR to_wallet_id = $1 ORDER BY created_at DESC LIMIT $2",
      [w.id, limit]
    );
    return r.rows;
  }
}
