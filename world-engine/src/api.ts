import { IncomingMessage, ServerResponse } from "http";
import { query } from "./db.js";
import { config, KNOWN_UUIDS } from "./config.js";
import { randomBytes, scryptSync, createHash } from "crypto";

interface Route {
  method: string;
  path: RegExp;
  handler: (req: IncomingMessage, res: ServerResponse, matches: RegExpMatchArray) => Promise<void>;
}

const routes: Route[] = [];
function addRoute(method: string, pattern: string, handler: Route["handler"]) { routes.push({ method, path: new RegExp(`^${pattern}$`), handler }); }
function json(res: ServerResponse, data: unknown, status = 200) { res.writeHead(status, { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }); res.end(JSON.stringify(data)); }
function body(req: IncomingMessage): Promise<Record<string, unknown>> { return new Promise((resolve) => { let data = ""; req.on("data", (chunk) => (data += chunk)); req.on("end", () => { try { resolve(JSON.parse(data)); } catch { resolve({}); } }); }); }
async function isStaff(staffId: unknown): Promise<boolean> {
  if (!staffId) return false;
  const r = await query("SELECT role FROM accounts_profile WHERE id = $1", [staffId]);
  if (!r.rows[0]) return false;
  return ["admin","owner","moderator","staff"].includes(r.rows[0].role);
}

// ===== NAKAMA AUTH =====
const NAKAMA_URL = "http://nakama:7350";
const NAKAMA_AUTH = "Basic " + Buffer.from("darkworld-server-key:").toString("base64");

addRoute("POST", "/auth/register", async (req, res) => {
  const b = await body(req);
  const deviceId = b.device_id || ("dw-" + Date.now());
  try {
    const nakamaRes = await fetch(NAKAMA_URL + "/v2/account/authenticate/device?create=true", { method: "POST", headers: { "Authorization": NAKAMA_AUTH, "Content-Type": "application/json" }, body: JSON.stringify({ id: deviceId }) });
    const data = await nakamaRes.json() as any;
    json(res, { token: data.token, user_id: data.user_id, username: data.username, created: data.created }, 201);
  } catch (e: any) { json(res, { error: "nakama_unavailable" }, 502); }
});

addRoute("POST", "/auth/restore", async (req, res) => {
  const b = await body(req);
  if (!b.token) return json(res, { error: "token required" }, 400);
  try {
    const nakamaRes = await fetch(NAKAMA_URL + "/v2/account", { headers: { "Authorization": "Bearer " + b.token } });
    if (!nakamaRes.ok) return json(res, { error: "invalid_token" }, 401);
    const data = await nakamaRes.json() as any;
    json(res, { account: data });
  } catch (e: any) { json(res, { error: "nakama_unavailable" }, 502); }
});

// ===== GAME ROUTES =====

addRoute("GET", "/health", async (_req, res) => {
  json(res, { status: "ok", uptime: process.uptime(), version: "5.0.0-zero-trust", modules: ["DeathModule","AfterlifeModule","DragonModule","TerritoryModule","FactionModule","AuditModule","CharacterStatsModule","ItemModule","InventoryModule","EquipmentModule","WalletModule","QuestModule","NPCModule","CombatPrepModule","LootModule","VIPModule","StoreModule","ChatModule","ClanModule","RankingModule","AdminModule","EventModule","AIProviderModule","AuthRealModule","FriendsModule","MultiplayerModule","SecurityLogModule","WorldSimulationModule","ClassModule","WarModule","KingdomWarModule","TroopModule","TerritoryMapModule","LoreModule","PublicApiModule","TwitchModule","AICoachModule","LiveWindowModule","TrustEngineModule","FraudEngineModule","AntiCheatModule","GovernanceModule"] });
});

addRoute("GET", "/worlds", async (_req, res) => {
  const result = await query("SELECT id, slug, name, world_type, description FROM worlds ORDER BY name");
  json(res, { worlds: result.rows });
});

addRoute("GET", "/worlds/([^/]+)/entities", async (_req, res, matches) => {
  const result = await query("SELECT id, entity_type, name, position_x, position_y, position_z, status, state FROM entities WHERE world_id = $1 AND deleted_at IS NULL", [matches[1]]);
  json(res, { entities: result.rows });
});

addRoute("POST", "/test/account", async (req, res) => {
  const b = await body(req);
  const name = b.display_name || "Heroi Teste";
  const result = await query("INSERT INTO accounts_profile (id, display_name) VALUES (gen_random_uuid(), $1) RETURNING *", [name]);
  const uid = result.rows[0].id;
  await query("INSERT INTO login_history (user_id, ip, device, platform, success) VALUES ($1,$2,$3,$4,true)", [uid, (req.headers["x-forwarded-for"] as string || req.socket.remoteAddress || "unknown"), b.device || "godot", b.platform || "mac"]);
  await query("UPDATE accounts_profile SET last_login_at = NOW() WHERE id = $1", [uid]);
  json(res, { account: result.rows[0] }, 201);
});

addRoute("POST", "/test/character", async (req, res) => {
  const b = await body(req);
  if (!b.account_id) return json(res, { error: "account_id required" }, 400);
  const name = b.character_name || "Heroi Teste";
  const ent = await query("INSERT INTO entities (id, world_id, entity_type, name, owner_account_id, position_x, position_y) VALUES (gen_random_uuid(), $1, $2, $3, $4, 100, 100) RETURNING *", [KNOWN_UUIDS.WORLD_LIVING, "player_character", name, b.account_id]);
  const chr = await query("INSERT INTO characters (id, account_id, entity_id, character_name, character_role, life_state) VALUES (gen_random_uuid(), $1, $2, $3, $4, $5) RETURNING *", [b.account_id, ent.rows[0].id, name, b.character_role || "wanderer", "alive"]);
  const cid = chr.rows[0].id;
  await query("INSERT INTO character_stats (character_id, zorium) VALUES ($1, 50) ON CONFLICT DO NOTHING", [cid]);
  await query("INSERT INTO wallets (character_id, balance) VALUES ($1, 50) ON CONFLICT DO NOTHING", [cid]);
  await query("INSERT INTO zorium_ledger (user_id, character_id, amount, tx_type, source, reason, created_by) VALUES ($1,$2,50,'admin_grant','system','Initial character grant','system')", [b.account_id, cid]);
  await query("INSERT INTO character_origins (character_id, origin_name, homeland) VALUES ($1, 'Viajante do Vale Cinzento', 'Vale Cinzento') ON CONFLICT DO NOTHING", [cid]);
  await query("INSERT INTO character_allegiances (character_id, allegiance_type) VALUES ($1, 'wanderer') ON CONFLICT DO NOTHING", [cid]);
  await query("INSERT INTO character_biographies (character_id, origin_name, birth_homeland) VALUES ($1, 'Viajante do Vale Cinzento', 'Vale Cinzento') ON CONFLICT DO NOTHING", [cid]);
  await query("INSERT INTO character_reputation (character_id, target_type, target_id, reputation_score) VALUES ($1, 'world', 'world', 0) ON CONFLICT DO NOTHING", [cid]);
  await query("INSERT INTO character_timeline (character_id, event_type, title, description) VALUES ($1, 'birth', 'Nascimento', 'Despertou no Vale Cinzento pela primeira vez') ON CONFLICT DO NOTHING", [cid]);
  json(res, { character: chr.rows[0], entity: ent.rows[0] }, 201);
});

addRoute("GET", "/characters/([^/]+)", async (_req, res, matches) => {
  const result = await query("SELECT c.*, e.name as entity_name, e.position_x, e.position_y, e.position_z, e.world_id, w.name as world_name FROM characters c JOIN entities e ON c.entity_id = e.id JOIN worlds w ON e.world_id = w.id WHERE c.id = $1 OR c.entity_id = $1", [matches[1]]);
  if (!result.rows[0]) return json(res, { error: "not found" }, 404);
  json(res, { character: result.rows[0] });
});

addRoute("POST", "/events/character-died", async (req, res) => {
  const b = await body(req);
  if (!b.entity_id) return json(res, { error: "entity_id required" }, 400);
  const result = await query("INSERT INTO events (event_type, target_entity_id, world_id, payload, created_by) VALUES ('CHARACTER_DIED', $1, $2, $3::jsonb, $4) RETURNING id", [b.entity_id, KNOWN_UUIDS.WORLD_LIVING, JSON.stringify({}), "godot_client"]);
  await query("INSERT INTO event_queue (event_id, priority) VALUES ($1, 10)", [result.rows[0].id]);
  json(res, { event: result.rows[0], message: "Death event created. Engine will process." }, 201);
});

addRoute("POST", "/events/afterlife-returned", async (req, res) => {
  const b = await body(req);
  if (!b.entity_id) return json(res, { error: "entity_id required" }, 400);
  const result = await query("INSERT INTO events (event_type, target_entity_id, world_id, payload, created_by) VALUES ('AFTERLIFE_RETURNED', $1, $2, $3::jsonb, $4) RETURNING id", [b.entity_id, KNOWN_UUIDS.WORLD_FROZEN, JSON.stringify({}), "godot_client"]);
  await query("INSERT INTO event_queue (event_id, priority) VALUES ($1, 10)", [result.rows[0].id]);
  json(res, { event: result.rows[0], message: "Return event created. Engine will process." }, 201);
});

addRoute("GET", "/events/recent", async (_req, res) => {
  const result = await query("SELECT id, event_type, source_entity_id, target_entity_id, world_id, status, created_at FROM events ORDER BY created_at DESC LIMIT 20");
  json(res, { events: result.rows });
});

addRoute("GET", "/dragons", async (_req, res) => {
  const result = await query("SELECT d.*, e.name, e.position_x, e.position_y, e.position_z FROM dragons d JOIN entities e ON d.entity_id = e.id WHERE d.is_alive = true");
  json(res, { dragons: result.rows });
});

// ===== RPG FOUNDATION =====

addRoute("GET", "/characters/([^/]+)/stats", async (_req, res, matches) => {
  const cid = matches[1];
  let stats = await query("SELECT * FROM character_stats WHERE character_id = $1", [cid]);
  if (!stats.rows[0]) {
    await query("INSERT INTO character_stats (character_id) VALUES ($1) ON CONFLICT DO NOTHING", [cid]);
    stats = await query("SELECT * FROM character_stats WHERE character_id = $1", [cid]);
  }
  json(res, { stats: stats.rows[0] });
});

addRoute("PUT", "/characters/([^/]+)/stats", async (req, res, matches) => {
  const b = await body(req);
  if (b.add_xp) {
    const xp = parseInt(b.add_xp as string);
    const stats = await query("SELECT * FROM character_stats WHERE character_id = $1", [matches[1]]);
    if (!stats.rows[0]) return json(res, { error: "Stats not found" }, 404);
    const newXp = stats.rows[0].xp + xp;
    let newLevel = stats.rows[0].level;
    const xpTable = [0,100,250,500,800,1200,1700,2300,3000,4000,5200,6600,8200,10000,12500,15500,19000,23000,28000,34000];
    while (newLevel < xpTable.length && newXp >= xpTable[newLevel]) newLevel++;
    const hpGain = (newLevel - stats.rows[0].level) * 10;
    const manaGain = (newLevel - stats.rows[0].level) * 5;
    await query("UPDATE character_stats SET xp=$1, level=$2, max_hp=max_hp+$3, hp=LEAST(hp+$3,max_hp+$3), max_mana=max_mana+$4, mana=LEAST(mana+$4,max_mana+$4), updated_at=NOW() WHERE character_id=$5", [newXp, newLevel, hpGain, manaGain, matches[1]]);
    json(res, { xp: newXp, level: newLevel, leveledUp: newLevel > stats.rows[0].level });
  } else {
    json(res, { error: "Provide add_xp" }, 400);
  }
});

addRoute("GET", "/characters/([^/]+)/inventory", async (_req, res, matches) => {
  const r = await query("SELECT i.*, it.name as item_name, it.item_type, it.rarity, it.base_stats, it.description FROM inventory i JOIN items it ON i.item_id = it.id WHERE i.character_id = $1 ORDER BY i.slot_index", [matches[1]]);
  json(res, { inventory: r.rows });
});

addRoute("POST", "/characters/([^/]+)/inventory", async (req, res, matches) => {
  const b = await body(req);
  if (!b.item_id) return json(res, { error: "item_id required" }, 400);
  const qty = parseInt((b.quantity as string) || "1");
  const used = await query("SELECT slot_index FROM inventory WHERE character_id = $1", [matches[1]]);
  const usedSet = new Set(used.rows.map((r: any) => r.slot_index));
  let slot = -1;
  for (let s = 0; s < 20; s++) { if (!usedSet.has(s)) { slot = s; break; } }
  if (slot === -1) return json(res, { error: "Inventory full" }, 400);
  const r = await query("INSERT INTO inventory (character_id, item_id, slot_index, quantity) VALUES ($1,$2,$3,$4) RETURNING *", [matches[1], b.item_id, slot, qty]);
  const itemInfo = await query("SELECT item_type FROM items WHERE id = $1", [b.item_id]);
  if (itemInfo.rows[0]?.item_type === "weapon") {
    await query("INSERT INTO weapon_upgrades (item_id, character_id) VALUES ($1,$2) ON CONFLICT (item_id, character_id) DO NOTHING", [b.item_id, matches[1]]);
  }
  json(res, { added: r.rows[0] }, 201);
});

addRoute("DELETE", "/characters/([^/]+)/inventory/([0-9]+)", async (_req, res, matches) => {
  await query("DELETE FROM inventory WHERE character_id = $1 AND slot_index = $2", [matches[1], parseInt(matches[2])]);
  json(res, { removed: true });
});

addRoute("GET", "/characters/([^/]+)/equipment", async (_req, res, matches) => {
  const r = await query("SELECT e.*, i.name as item_name, i.rarity, i.base_stats FROM equipment e JOIN items i ON e.item_id = i.id WHERE e.character_id = $1", [matches[1]]);
  json(res, { equipment: r.rows });
});

addRoute("POST", "/characters/([^/]+)/equipment/equip", async (req, res, matches) => {
  const b = await body(req);
  if (!b.item_id || !b.slot_type) return json(res, { error: "item_id and slot_type required" }, 400);
  await query("INSERT INTO equipment (character_id, slot_type, item_id) VALUES ($1,$2,$3) ON CONFLICT (character_id, slot_type) DO UPDATE SET item_id = $3, created_at = NOW()", [matches[1], b.slot_type, b.item_id]);
  json(res, { equipped: true, slot: b.slot_type });
});

addRoute("POST", "/characters/([^/]+)/equipment/unequip", async (req, res, matches) => {
  const b = await body(req);
  if (!b.slot_type) return json(res, { error: "slot_type required" }, 400);
  const r = await query("DELETE FROM equipment WHERE character_id = $1 AND slot_type = $2 RETURNING *", [matches[1], b.slot_type]);
  json(res, { unequipped: r.rows.length > 0 });
});

addRoute("GET", "/characters/([^/]+)/wallet", async (_req, res, matches) => {
  await query("INSERT INTO wallets (character_id, balance) VALUES ($1, 0) ON CONFLICT (character_id) DO NOTHING", [matches[1]]);
  const r = await query("SELECT * FROM wallets WHERE character_id = $1", [matches[1]]);
  json(res, { wallet: r.rows[0] });
});

addRoute("POST", "/wallets/transfer", async (req, res) => {
  const b = await body(req);
  if (!b.from_character_id || !b.to_character_id || !b.amount) return json(res, { error: "from_character_id, to_character_id, amount required" }, 400);
  const amt = parseFloat(b.amount as string);
  const from = await query("SELECT * FROM wallets WHERE character_id = $1", [b.from_character_id]);
  if (!from.rows[0] || parseFloat(from.rows[0].balance) < amt) return json(res, { error: "Insufficient zorium" }, 400);
  await query("UPDATE wallets SET balance = balance - $1 WHERE character_id = $2", [amt, b.from_character_id]);
  await query("INSERT INTO wallets (character_id, balance) VALUES ($1, 0) ON CONFLICT (character_id) DO NOTHING", [b.to_character_id]);
  await query("UPDATE wallets SET balance = balance + $1 WHERE character_id = $2", [amt, b.to_character_id]);
  json(res, { transferred: amt });
});

addRoute("GET", "/items", async (_req, res) => {
  const r = await query("SELECT * FROM items ORDER BY rarity, item_type, name");
  json(res, { items: r.rows });
});

addRoute("GET", "/characters/([^/]+)/quests", async (_req, res, matches) => {
  const r = await query("SELECT qp.*, qd.name as quest_name, qd.description, qd.rewards FROM quest_progress qp JOIN quest_data qd ON qp.quest_id = qd.id WHERE qp.character_id = $1 ORDER BY qp.created_at DESC", [matches[1]]);
  json(res, { quests: r.rows });
});

addRoute("POST", "/characters/([^/]+)/quests/accept", async (req, res, matches) => {
  const b = await body(req);
  if (!b.quest_id) return json(res, { error: "quest_id required" }, 400);
  const existing = await query("SELECT * FROM quest_progress WHERE character_id = $1 AND quest_id = $2", [matches[1], b.quest_id]);
  if (existing.rows[0]) return json(res, { error: "Quest already tracked" }, 400);
  const r = await query("INSERT INTO quest_progress (character_id, quest_id, state, started_at) VALUES ($1,$2,'active',NOW()) RETURNING *", [matches[1], b.quest_id]);
  json(res, { quest: r.rows[0] }, 201);
});

addRoute("GET", "/npcs/([^/]+)/profile", async (_req, res, matches) => {
  await query("INSERT INTO npc_profiles (entity_id, role) VALUES ($1, 'villager') ON CONFLICT (entity_id) DO NOTHING", [matches[1]]);
  const r = await query("SELECT * FROM npc_profiles WHERE entity_id = $1", [matches[1]]);
  json(res, { profile: r.rows[0] });
});

addRoute("GET", "/characters/([^/]+)/load", async (_req, res, matches) => {
  const r = await query("SELECT * FROM save_states WHERE character_id = $1 ORDER BY saved_at DESC LIMIT 1", [matches[1]]);
  json(res, { save: r.rows[0] || null });
});

addRoute("POST", "/characters/([^/]+)/save", async (req, res, matches) => {
  const b = await body(req);
  const pos = b.position || { x: 0, y: 3, z: 0 };
  const stats = await query("SELECT * FROM character_stats WHERE character_id = $1", [matches[1]]);
  const inv = await query("SELECT item_id, slot_index, quantity FROM inventory WHERE character_id = $1", [matches[1]]);
  const equip = await query("SELECT slot_type, item_id FROM equipment WHERE character_id = $1", [matches[1]]);
  const quests = await query("SELECT quest_id, state, progress FROM quest_progress WHERE character_id = $1", [matches[1]]);
  await query(
    "INSERT INTO save_states (character_id, position, stats_snapshot, inventory_snapshot, equipment_snapshot, quest_snapshot) VALUES ($1,$2,$3,$4,$5,$6)",
    [matches[1], JSON.stringify(pos), JSON.stringify(stats.rows[0] || {}), JSON.stringify(inv.rows), JSON.stringify(equip.rows), JSON.stringify(quests.rows)]
  );
  json(res, { saved: true, timestamp: new Date().toISOString() }, 201);
});

// ===== HEAL & LOOT =====

addRoute("POST", "/characters/([^/]+)/heal", async (req, res, matches) => {
  const cid = matches[1];
  const cost = 5;
  const w = await query("SELECT * FROM wallets WHERE character_id = $1", [cid]);
  if (!w.rows[0] || parseFloat(w.rows[0].balance) < cost) return json(res, { error: "Insufficient zorium", cost }, 400);
  await query("UPDATE wallets SET balance = balance - $1, updated_at = NOW() WHERE character_id = $2", [cost, cid]);
  await query("UPDATE character_stats SET zorium = zorium - $1, hp = max_hp, updated_at = NOW() WHERE character_id = $2", [cost, cid]);
  await query("INSERT INTO transactions (from_wallet_id, amount, tx_type, description) VALUES ($1,$2,'purchase','heal')", [w.rows[0].id, cost]);
  const uid = (await query("SELECT account_id FROM characters WHERE id = $1", [cid])).rows[0]?.account_id;
  await query("INSERT INTO zorium_ledger (user_id, character_id, amount, tx_type, source, reason, created_by) VALUES ($1,$2,$3,'heal','npc','Curandeira heal','system')", [uid, cid, -cost]);
  const stats = await query("SELECT hp, max_hp, zorium FROM character_stats WHERE character_id = $1", [cid]);
  json(res, { healed: true, cost, stats: stats.rows[0] });
});

addRoute("POST", "/characters/([^/]+)/spend", async (req, res, matches) => {
  const cid = matches[1];
  const b = await body(req);
  const amount = parseFloat(b.amount as string);
  const desc = (b.description as string) || "purchase";
  if (!amount || amount <= 0) return json(res, { error: "Invalid amount" }, 400);
  const w = await query("SELECT * FROM wallets WHERE character_id = $1", [cid]);
  if (!w.rows[0] || parseFloat(w.rows[0].balance) < amount) return json(res, { error: "Insufficient zorium", required: amount }, 400);
  await query("UPDATE wallets SET balance = balance - $1, updated_at = NOW() WHERE character_id = $2", [amount, cid]);
  await query("UPDATE character_stats SET zorium = zorium - $1, updated_at = NOW() WHERE character_id = $2", [amount, cid]);
  await query("INSERT INTO transactions (from_wallet_id, amount, tx_type, description) VALUES ($1,$2,'purchase',$3)", [w.rows[0].id, amount, desc]);
  const uid2 = (await query("SELECT account_id FROM characters WHERE id = $1", [cid])).rows[0]?.account_id;
  await query("INSERT INTO zorium_ledger (user_id, character_id, amount, tx_type, source, reason, created_by) VALUES ($1,$2,$3,'shop_purchase','game',$4,'system')", [uid2, cid, -amount, desc]);
  const bal = await query("SELECT balance FROM wallets WHERE character_id = $1", [cid]);
  json(res, { spent: amount, balance: parseFloat(bal.rows[0].balance), description: desc });
});

addRoute("GET", "/loot/([^/]+)/([^/]+)", async (_req, res, matches) => {
  const r = await query(
    "SELECT lt.*, i.name as item_name, i.rarity, i.base_stats FROM loot_tables lt JOIN items i ON lt.item_id = i.id WHERE lt.source_type = $1 AND lt.source_id = $2",
    [matches[1], matches[2]]
  );
  json(res, { loot_table: r.rows });
});

addRoute("POST", "/loot/([^/]+)/([^/]+)/roll", async (_req, res, matches) => {
  const table = await query(
    "SELECT lt.*, i.name as item_name FROM loot_tables lt JOIN items i ON lt.item_id = i.id WHERE lt.source_type = $1 AND lt.source_id = $2",
    [matches[1], matches[2]]
  );
  const drops: Array<{ item_id: string; item_name: string; quantity: number }> = [];
  for (const entry of table.rows) {
    if (Math.random() <= parseFloat(entry.drop_chance)) {
      const qty = entry.min_qty + Math.floor(Math.random() * (entry.max_qty - entry.min_qty + 1));
      drops.push({ item_id: entry.item_id, item_name: entry.item_name, quantity: qty });
    }
  }
  json(res, { drops });
});

addRoute("POST", "/npcs/([^/]+)/memory", async (req, res, matches) => {
  const b = await body(req);
  await query(
    "INSERT INTO npc_memory (npc_entity_id, character_id, memory_type, content, importance) VALUES ($1,$2,$3,$4,$5)",
    [matches[1], b.character_id || null, b.memory_type || "interaction", JSON.stringify(b.content || {}), b.importance || 5]
  );
  json(res, { recorded: true }, 201);
});

// ===== PLATFORM GAMMA =====

addRoute("GET", "/store/products", async (_req, res) => {
  const r = await query("SELECT p.*, c.name as category FROM store_products p JOIN store_categories c ON p.category_id = c.id ORDER BY c.sort_order, p.name");
  json(res, { products: r.rows, mode: "sandbox" });
});

addRoute("POST", "/store/checkout/create", async (req, res) => {
  const b = await body(req);
  if (!b.user_id || !b.product_id) return json(res, { error: "user_id and product_id required" }, 400);
  const product = await query("SELECT * FROM store_products WHERE id = $1", [b.product_id]);
  if (!product.rows[0]) return json(res, { error: "Product not found" }, 404);
  json(res, { mode: "sandbox", message: "Stripe not active. Purchase pending.", product: product.rows[0] });
});

addRoute("POST", "/store/webhook/stripe", async (req, res) => {
  const b = await body(req);
  await query("INSERT INTO webhook_logs (event_type, stripe_event_id, payload) VALUES ($1,$2,$3)", [b.type || "unknown", b.id || "sandbox", JSON.stringify(b)]);
  json(res, { received: true, mode: "sandbox" });
});

const chatFlood = new Map<string, number>();
addRoute("POST", "/chat/send", async (req, res) => {
  const b = await body(req);
  if (!b.message) return json(res, { error: "message required" }, 400);
  const uid = (b.user_id as string) || "anon";
  const now = Date.now();
  if (chatFlood.has(uid) && now - chatFlood.get(uid)! < 2000) return json(res, { error: "Rate limit: aguarde 2 segundos" }, 429);
  chatFlood.set(uid, now);
  const msg = (b.message as string).toLowerCase();
  const rules = (await query("SELECT pattern, action FROM chat_moderation_rules WHERE is_active = true")).rows;
  for (const rule of rules) {
    if (msg.includes(rule.pattern.toLowerCase())) {
      if (rule.action === "block") return json(res, { error: "Mensagem bloqueada por regra de moderacao" }, 403);
      if (rule.action === "flag") { b._flagged = true; }
    }
  }
  const status = b._flagged ? "flagged" : "ok";
  const r = await query("INSERT INTO chat_messages (user_id, character_id, display_name, vip_level, role, message, channel, moderation_status) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *",
    [b.user_id || null, b.character_id || null, b.display_name || "Anonimo", b.vip_level || 0, b.role || "player", b.message, b.channel || "global", status]);
  json(res, { message: r.rows[0] }, 201);
});

addRoute("GET", "/chat/recent", async (_req, res) => {
  const r = await query("SELECT * FROM chat_messages WHERE channel = 'global' AND moderation_status = 'ok' ORDER BY created_at DESC LIMIT 30");
  json(res, { messages: r.rows.reverse() });
});

addRoute("GET", "/chat/([^/]+)", async (_req, res, matches) => {
  const r = await query("SELECT * FROM chat_messages WHERE channel = $1 AND moderation_status = 'ok' ORDER BY created_at DESC LIMIT 30", [matches[1]]);
  json(res, { messages: r.rows.reverse() });
});

addRoute("GET", "/clans", async (_req, res) => {
  json(res, { clans: (await query("SELECT * FROM clans ORDER BY member_count DESC LIMIT 50")).rows });
});

addRoute("POST", "/clans/create", async (req, res) => {
  const b = await body(req);
  if (!b.name || !b.tag || !b.leader_user_id) return json(res, { error: "name, tag, leader_user_id required" }, 400);
  const clan = await query("INSERT INTO clans (name, tag, description, leader_user_id) VALUES ($1,$2,$3,$4) RETURNING *", [b.name, b.tag, b.description || "", b.leader_user_id]);
  await query("INSERT INTO clan_members (clan_id, user_id, role) VALUES ($1,$2,'leader')", [clan.rows[0].id, b.leader_user_id]);
  json(res, { clan: clan.rows[0] }, 201);
});

addRoute("POST", "/clans/([^/]+)/join", async (req, res, matches) => {
  const b = await body(req);
  if (!b.user_id) return json(res, { error: "user_id required" }, 400);
  await query("INSERT INTO clan_members (clan_id, user_id, role) VALUES ($1,$2,'member') ON CONFLICT DO NOTHING", [matches[1], b.user_id]);
  await query("UPDATE clans SET member_count = member_count + 1 WHERE id = $1", [matches[1]]);
  json(res, { joined: true });
});

addRoute("POST", "/clans/([^/]+)/leave", async (req, res, matches) => {
  const b = await body(req);
  await query("DELETE FROM clan_members WHERE clan_id = $1 AND user_id = $2", [matches[1], b.user_id]);
  await query("UPDATE clans SET member_count = GREATEST(member_count - 1, 0) WHERE id = $1", [matches[1]]);
  json(res, { left: true });
});

addRoute("GET", "/clans/([^/]+)/members", async (_req, res, matches) => {
  const r = await query("SELECT cm.*, ap.display_name FROM clan_members cm JOIN accounts_profile ap ON cm.user_id = ap.id WHERE cm.clan_id = $1 ORDER BY cm.role, cm.joined_at", [matches[1]]);
  json(res, { members: r.rows });
});

addRoute("GET", "/rankings/global", async (_req, res) => {
  const r = await query("SELECT re.*, ap.display_name FROM ranking_entries re JOIN accounts_profile ap ON re.user_id = ap.id WHERE re.ranking_type = 'xp' ORDER BY re.score DESC LIMIT 50");
  json(res, { rankings: r.rows });
});

addRoute("GET", "/rankings/season", async (_req, res) => {
  const season = await query("SELECT * FROM ranking_seasons WHERE status = 'active' LIMIT 1");
  if (!season.rows[0]) return json(res, { rankings: [], season: null });
  const r = await query("SELECT re.*, ap.display_name FROM ranking_entries re JOIN accounts_profile ap ON re.user_id = ap.id WHERE re.season_id = $1 ORDER BY re.score DESC LIMIT 50", [season.rows[0].id]);
  json(res, { rankings: r.rows, season: season.rows[0] });
});

addRoute("GET", "/rankings/clans", async (_req, res) => {
  json(res, { rankings: (await query("SELECT * FROM clans ORDER BY level DESC, member_count DESC LIMIT 50")).rows });
});

addRoute("GET", "/vip/levels", async (_req, res) => {
  json(res, { levels: (await query("SELECT * FROM vip_levels ORDER BY level")).rows });
});

addRoute("GET", "/characters/([^/]+)/vip", async (_req, res, matches) => {
  const chr = await query("SELECT account_id FROM characters WHERE id = $1", [matches[1]]);
  if (!chr.rows[0]) return json(res, { vip: null });
  const vip = await query("SELECT uv.*, vl.name, vl.badge, vl.color FROM user_vip uv JOIN vip_levels vl ON uv.vip_level = vl.level WHERE uv.user_id = $1 AND uv.status = 'active' ORDER BY uv.vip_level DESC LIMIT 1", [chr.rows[0].account_id]);
  json(res, { vip: vip.rows[0] || null });
});

addRoute("POST", "/admin/grant-zorium", async (req, res) => {
  const b = await body(req);
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized: staff role required" }, 403);
  if (!b.character_id || !b.amount) return json(res, { error: "character_id and amount required" }, 400);
  const amt = parseFloat(b.amount as string);
  await query("UPDATE wallets SET balance = balance + $1, updated_at = NOW() WHERE character_id = $2", [amt, b.character_id]);
  await query("UPDATE character_stats SET zorium = zorium + $1, updated_at = NOW() WHERE character_id = $2", [amt, b.character_id]);
  const uid = (await query("SELECT account_id FROM characters WHERE id = $1", [b.character_id])).rows[0]?.account_id;
  await query("INSERT INTO zorium_ledger (user_id, character_id, amount, tx_type, source, reason, created_by) VALUES ($1,$2,$3,'admin_grant','admin',$4,$5)", [uid, b.character_id, amt, b.reason || "Admin grant", b.granted_by || "system"]);
  json(res, { granted: amt });
});

addRoute("POST", "/admin/ban", async (req, res) => {
  const b = await body(req);
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized: staff role required" }, 403);
  if (!b.user_id || !b.ban_type) return json(res, { error: "user_id and ban_type required" }, 400);
  const isPerm = b.ban_type === "perm_ban";
  await query("INSERT INTO ban_records (user_id, staff_id, ban_type, reason, expires_at, violation_type, owner_only) VALUES ($1,$2,$3,$4,$5,$6,$7)", [b.user_id, b.staff_id || null, b.ban_type, b.reason || "", b.expires_at || null, b.violation_type, isPerm]);
  await query("UPDATE accounts_profile SET is_banned = true, status = 'banned' WHERE id = $1", [b.user_id]);
  await query("INSERT INTO moderation_logs (staff_id, target_user_id, action, reason) VALUES ($1::uuid,$2,$3,$4)", [b.staff_id, b.user_id, 'ban_' + b.ban_type, b.reason || ""]);
  json(res, { banned: true, owner_only: isPerm });
});

addRoute("POST", "/admin/unban", async (req, res) => {
  const b = await body(req);
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized: staff role required" }, 403);
  if (!b.user_id) return json(res, { error: "user_id required" }, 400);
  const permBans = (await query("SELECT * FROM ban_records WHERE user_id = $1 AND is_active = true AND owner_only = true", [b.user_id])).rows;
  if (permBans.length > 0) {
    const staff = (await query("SELECT role FROM accounts_profile WHERE id = $1", [b.staff_id])).rows[0];
    if (staff?.role !== "owner") return json(res, { error: "Only OWNER can remove permanent bans" }, 403);
  }
  await query("UPDATE ban_records SET is_active = false WHERE user_id = $1", [b.user_id]);
  await query("UPDATE accounts_profile SET is_banned = false, status = 'active' WHERE id = $1", [b.user_id]);
  await query("INSERT INTO moderation_logs (staff_id, target_user_id, action, reason) VALUES ($1::uuid,$2,'unban','Unbanned')", [b.staff_id, b.user_id]);
  json(res, { unbanned: true });
});

// ===== GOVERNANCE =====

addRoute("POST", "/auth/accept-terms", async (req, res) => {
  const b = await body(req);
  if (!b.user_id) return json(res, { error: "user_id required" }, 400);
  await query("INSERT INTO terms_acceptance (user_id, terms_version, privacy_version, ip) VALUES ($1,'1.0.0','1.0.0',$2) ON CONFLICT DO NOTHING", [b.user_id, (req.headers["x-forwarded-for"] as string) || "unknown"]);
  json(res, { accepted: true });
});

addRoute("GET", "/auth/terms-status", async (req, res) => {
  const b = await body(req).catch(() => ({}));
  if (!b.user_id) return json(res, { accepted: false });
  const r = (await query("SELECT * FROM terms_acceptance WHERE user_id = $1 ORDER BY accepted_at DESC LIMIT 1", [b.user_id])).rows[0];
  json(res, { accepted: !!r, terms: r || null });
});

addRoute("PUT", "/auth/kyc", async (req, res) => {
  const b = await body(req);
  if (!b.user_id) return json(res, { error: "user_id required" }, 400);
  if (b.phone) await query("UPDATE accounts_profile SET phone = $1 WHERE id = $2", [b.phone, b.user_id]);
  if (b.birthdate) await query("UPDATE accounts_profile SET birthdate = $1 WHERE id = $2", [b.birthdate, b.user_id]);
  if (b.city) await query("UPDATE accounts_profile SET city = $1 WHERE id = $2", [b.city, b.user_id]);
  json(res, { updated: true });
});

addRoute("GET", "/violations", async (_req, res) => {
  json(res, { violations: (await query("SELECT * FROM violation_catalog ORDER BY category, severity DESC")).rows });
});

addRoute("GET", "/forum/categories", async (_req, res) => {
  json(res, { categories: (await query("SELECT * FROM forum_categories ORDER BY sort_order")).rows });
});

addRoute("GET", "/forum/threads", async (_req, res) => {
  json(res, { threads: (await query("SELECT ft.*, ap.display_name, fc.name as category_name FROM forum_threads ft JOIN accounts_profile ap ON ft.user_id = ap.id JOIN forum_categories fc ON ft.category_id = fc.id ORDER BY ft.is_pinned DESC, ft.updated_at DESC LIMIT 50")).rows });
});

addRoute("POST", "/forum/threads", async (req, res) => {
  const b = await body(req);
  if (!b.user_id || !b.category_id || !b.title || !b.content) return json(res, { error: "user_id, category_id, title, content required" }, 400);
  const t = (await query("INSERT INTO forum_threads (category_id, user_id, title) VALUES ($1,$2,$3) RETURNING *", [b.category_id, b.user_id, b.title])).rows[0];
  await query("INSERT INTO forum_posts (thread_id, user_id, content) VALUES ($1,$2,$3)", [t.id, b.user_id, b.content]);
  json(res, { thread: t }, 201);
});

addRoute("POST", "/forum/posts", async (req, res) => {
  const b = await body(req);
  if (!b.thread_id || !b.user_id || !b.content) return json(res, { error: "thread_id, user_id, content required" }, 400);
  const p = (await query("INSERT INTO forum_posts (thread_id, user_id, content) VALUES ($1,$2,$3) RETURNING *", [b.thread_id, b.user_id, b.content])).rows[0];
  await query("UPDATE forum_threads SET updated_at = NOW() WHERE id = $1", [b.thread_id]);
  json(res, { post: p }, 201);
});

addRoute("POST", "/tickets", async (req, res) => {
  const b = await body(req);
  if (!b.user_id || !b.title || !b.category) return json(res, { error: "user_id, title, category required" }, 400);
  const t = (await query("INSERT INTO tickets (user_id, category, title) VALUES ($1,$2,$3) RETURNING *", [b.user_id, b.category, b.title])).rows[0];
  await query("INSERT INTO ticket_messages (ticket_id, user_id, content) VALUES ($1,$2,$3)", [t.id, b.user_id, b.message || b.title]);
  json(res, { ticket: t }, 201);
});

addRoute("GET", "/tickets", async (req, res) => {
  const b = await body(req).catch(() => ({}));
  if (!b.user_id) return json(res, { tickets: [] });
  json(res, { tickets: (await query("SELECT * FROM tickets WHERE user_id = $1 ORDER BY updated_at DESC LIMIT 50", [b.user_id])).rows });
});

addRoute("POST", "/chat/translate", async (req, res) => {
  const b = await body(req);
  if (!b.text) return json(res, { error: "text required" }, 400);
  const provider = process.env.AI_API_KEY ? "deepseek" : "offline";
  if (provider === "offline") return json(res, { translated: b.text, provider: "offline" });
  try {
    const aiRes = await fetch(process.env.AI_ENDPOINT + "/chat/completions", {
      method: "POST", headers: { "Authorization": "Bearer " + process.env.AI_API_KEY, "Content-Type": "application/json" },
      body: JSON.stringify({ model: process.env.AI_MODEL || "deepseek-chat", messages: [{ role: "system", content: "Translate this to Portuguese. Output only the translation." }, { role: "user", content: b.text }], max_tokens: 200, temperature: 0.3 })
    });
    const aiData = await aiRes.json() as any;
    const translated = aiData?.choices?.[0]?.message?.content || b.text;
    await query("INSERT INTO chat_translations (message_id, original_language, target_language, original_text, translated_text, provider) VALUES ($1,'auto','pt',$2,$3,'deepseek')", [b.message_id || null, b.text, translated]);
    json(res, { translated, provider: "deepseek" });
  } catch { json(res, { translated: b.text, provider: "error" }); }
});

addRoute("POST", "/admin/unban", async (req, res) => {
  const b = await body(req);
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized: staff role required" }, 403);
  if (!b.user_id) return json(res, { error: "user_id required" }, 400);
  await query("UPDATE ban_records SET is_active = false WHERE user_id = $1", [b.user_id]);
  await query("UPDATE accounts_profile SET is_banned = false, status = 'active' WHERE id = $1", [b.user_id]);
  await query("INSERT INTO moderation_logs (staff_id, target_user_id, action, reason) VALUES ($1::uuid,$2,'unban','Unbanned by moderation')", [b.staff_id, b.user_id]);
  json(res, { unbanned: true });
});

addRoute("POST", "/admin/announce", async (req, res) => {
  const b = await body(req);
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized: staff role required" }, 403);
  if (!b.title || !b.message) return json(res, { error: "title and message required" }, 400);
  const r = await query("INSERT INTO server_announcements (title, message, priority, created_by) VALUES ($1,$2,$3,$4) RETURNING *", [b.title, b.message, b.priority || 5, b.created_by || "system"]);
  json(res, { announcement: r.rows[0] }, 201);
});

addRoute("GET", "/events/active", async (_req, res) => {
  json(res, { events: (await query("SELECT * FROM game_events WHERE status = 'active' ORDER BY starts_at")).rows });
});

addRoute("GET", "/events/calendar", async (_req, res) => {
  const events = (await query("SELECT id, name, event_type, starts_at, ends_at, status FROM game_events ORDER BY starts_at")).rows;
  const maintenance = (await query("SELECT * FROM scheduled_maintenance WHERE status IN ('scheduled','active') ORDER BY starts_at")).rows;
  const announcements = (await query("SELECT * FROM server_announcements WHERE expires_at > NOW() ORDER BY priority DESC")).rows;
  json(res, { events, maintenance, announcements });
});

addRoute("GET", "/characters/([^/]+)/profile", async (_req, res, matches) => {
  await query("INSERT INTO player_profiles (user_id) SELECT account_id FROM characters WHERE id = $1 ON CONFLICT (user_id) DO NOTHING", [matches[1]]);
  const r = await query("SELECT pp.*, c.character_name, cs.level, cs.xp, cs.zorium, ap.display_name, ap.role, ap.vip_level FROM player_profiles pp JOIN characters c ON pp.character_id = c.id OR pp.user_id = c.account_id JOIN character_stats cs ON cs.character_id = c.id JOIN accounts_profile ap ON ap.id = pp.user_id WHERE c.id = $1 LIMIT 1", [matches[1]]);
  json(res, { profile: r.rows[0] || null });
});

addRoute("GET", "/characters/([^/]+)/titles", async (_req, res) => {
  json(res, { titles: (await query("SELECT * FROM player_titles ORDER BY rarity")).rows });
});

addRoute("GET", "/auth/login-history/([^/]+)", async (_req, res, matches) => {
  json(res, { history: (await query("SELECT * FROM login_history WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50", [matches[1]])).rows });
});

addRoute("POST", "/npcs/([^/]+)/chat", async (req, res, matches) => {
  const b = await body(req);
  const npcRole = matches[1];
  const msg = (b.message as string) || "Ola";
  const npcInfo = (await query("SELECT * FROM npc_lore WHERE npc_name ILIKE $1", ["%" + npcRole.replace(/_/g, " ") + "%"])).rows[0];
  const fallbacks: Record<string, string> = { blacksmith:"Posso forjar armas de ferro e aço. O que precisa?", healer:"Posso curar suas feridas. Use [C] para se curar por 5 Zorium.", guard:"Mantenha-se atento aos perigos da regiao. Vorak esta proximo.", merchant:"Tenho mercadorias para viajantes. Zorium e bem-vindo.", villager:"A vida era mais tranquila antes de Vorak. Tome cuidado.", guardian:"O dragao Vorak ameaca o Vale. Fale com a curandeira para aceitar a missao." };
  if (process.env.AI_API_KEY && process.env.AI_ENDPOINT) {
    try {
      const systemPrompt = `Voce e um NPC do jogo Dark World. Seu papel: ${npcInfo?.role || npcRole}. ${npcInfo?.biography || ""}. Regras: responda em portugues, maximo 3 frases, nao invente itens que nao existem, nao prometa pagamentos, nao de comandos admin. Seja imersivo e medieval.`;
      const aiRes = await fetch(process.env.AI_ENDPOINT + "/chat/completions", {
        method: "POST",
        headers: { "Authorization": "Bearer " + process.env.AI_API_KEY, "Content-Type": "application/json" },
        body: JSON.stringify({ model: process.env.AI_MODEL || "deepseek-chat", messages: [{ role: "system", content: systemPrompt }, { role: "user", content: msg }], max_tokens: 120, temperature: 0.7 })
      });
      const aiData = await aiRes.json() as any;
      const reply = aiData?.choices?.[0]?.message?.content || fallbacks[npcRole] || "...";
      return json(res, { reply, mode: "ai", model: process.env.AI_MODEL });
    } catch {}
  }
  json(res, { reply: fallbacks[npcRole] || "...", mode: "static" });
});

addRoute("GET", "/wallet/([^/]+)/ledger", async (_req, res, matches) => {
  const r = await query("SELECT * FROM zorium_ledger WHERE character_id = $1 ORDER BY created_at DESC LIMIT 50", [matches[1]]);
  json(res, { ledger: r.rows });
});

// ===== DELTA: AUTH, FRIENDS, MULTIPLAYER =====

function hashPw(pw: string): string { const s = randomBytes(16).toString("hex"); return s + ":" + scryptSync(pw, s, 64).toString("hex"); }
function verifyPw(pw: string, stored: string): boolean { const [s, h] = stored.split(":"); return scryptSync(pw, s, 64).toString("hex") === h; }

addRoute("POST", "/auth/register-email", async (req, res) => {
  const b = await body(req);
  if (!b.email || !b.password || !b.display_name) return json(res, { error: "email, password, display_name required" }, 400);
  const exists = await query("SELECT id FROM accounts_profile WHERE email = $1", [b.email]);
  if (exists.rows[0]) return json(res, { error: "Email already registered" }, 409);
  const hash = hashPw(b.password as string);
  const user = (await query("INSERT INTO accounts_profile (id,email,display_name,password_hash,username) VALUES (gen_random_uuid(),$1,$2,$3,$4) RETURNING id,email,display_name", [b.email, b.display_name, hash, (b.email as string).split("@")[0] + "_" + Date.now()])).rows[0];
  const token = randomBytes(32).toString("hex");
  await query("INSERT INTO email_verifications (user_id,token,email) VALUES ($1,$2,$3)", [user.id, token, b.email]);
  await query("INSERT INTO login_history (user_id,ip,success) VALUES ($1,$2,true)", [user.id, (req.headers["x-forwarded-for"] as string) || "unknown"]);
  await query("INSERT INTO security_logs (user_id,action,ip,risk_level) VALUES ($1,'register',$2,'low')", [user.id, (req.headers["x-forwarded-for"] as string) || "unknown"]);
  if (process.env.BREVO_API_KEY) {
    try {
      await fetch("https://api.brevo.com/v3/smtp/email", {
        method: "POST",
        headers: { "api-key": process.env.BREVO_API_KEY, "Content-Type": "application/json" },
        body: JSON.stringify({
          sender: { name: process.env.BREVO_SENDER_NAME || "Dark World", email: process.env.BREVO_SENDER || "noreply@zorionlabs.net" },
          to: [{ email: b.email, name: b.display_name }],
          subject: "Dark World — Verify your email",
          htmlContent: `<p>Welcome to Dark World, ${b.display_name}!</p><p><a href='https://dark.zorionlabs.net/verify?token=${token}'>Click here to verify your email</a></p>`
        })
      });
    } catch {}
  }
  json(res, { user, verification_token: token, brevo: process.env.BREVO_API_KEY ? "configured" : "not_configured" }, 201);
});

addRoute("POST", "/auth/login", async (req, res) => {
  const b = await body(req);
  if (!b.email || !b.password) return json(res, { error: "email and password required" }, 400);
  const ip = (req.headers["x-forwarded-for"] as string) || req.socket?.remoteAddress || "unknown";
  const user = (await query("SELECT * FROM accounts_profile WHERE email = $1", [b.email])).rows[0];
  if (!user || !user.password_hash) { json(res, { error: "Invalid credentials" }, 401); return; }
  if (user.is_banned) { json(res, { error: "Account banned" }, 403); return; }
  if (!verifyPw(b.password as string, user.password_hash)) {
    await query("INSERT INTO login_history (user_id,ip,success,failure_reason) VALUES ($1,$2,false,'wrong_password')", [user.id, ip]);
    await query("INSERT INTO security_logs (user_id,action,ip,risk_level,metadata) VALUES ($1,'login_failed',$2,'medium',$3)", [user.id, ip, JSON.stringify({email:b.email})]);
    return json(res, { error: "Invalid credentials" }, 401);
  }
  if (!user.email_verified) { return json(res, { error: "Email not verified. Check your inbox." }, 403); }
  const token = randomBytes(48).toString("hex");
  await query("INSERT INTO auth_sessions (user_id,token,ip,device) VALUES ($1,$2,$3,$4)", [user.id, token, ip, b.device || "web"]);
  await query("INSERT INTO login_history (user_id,ip,device,success) VALUES ($1,$2,$3,true)", [user.id, ip, b.device || "web"]);
  await query("UPDATE accounts_profile SET last_login_at=NOW() WHERE id=$1", [user.id]);
  json(res, { token, user: { id: user.id, email: user.email, display_name: user.display_name, role: user.role, vip_level: user.vip_level } });
});

addRoute("POST", "/auth/change-password", async (req, res) => {
  const b = await body(req);
  if (!b.email || !b.current_password || !b.new_password) return json(res, { error: "email, current_password, new_password required" }, 400);
  const user = (await query("SELECT * FROM accounts_profile WHERE email = $1", [b.email])).rows[0];
  if (!user || !user.password_hash) return json(res, { error: "Invalid credentials" }, 401);
  if (!verifyPw(b.current_password as string, user.password_hash)) return json(res, { error: "Current password incorrect" }, 401);
  const newHash = hashPw(b.new_password as string);
  await query("UPDATE accounts_profile SET password_hash = $1 WHERE id = $2", [newHash, user.id]);
  json(res, { changed: true });
});

addRoute("PUT", "/characters/([^/]+)/profile", async (req, res, matches) => {
  const b = await body(req);
  if (b.display_name) {
    const char = await query("SELECT account_id FROM characters WHERE id = $1", [matches[1]]);
    if (char.rows[0]) await query("UPDATE accounts_profile SET display_name = $1 WHERE id = $2", [b.display_name, char.rows[0].account_id]);
  }
  if (b.bio) await query("INSERT INTO player_profiles (user_id, bio) SELECT account_id, $1 FROM characters WHERE id = $2 ON CONFLICT (user_id) DO UPDATE SET bio = $1", [b.bio, matches[1]]);
  json(res, { updated: true });
});

addRoute("POST", "/auth/logout", async (req, res) => {
  const b = await body(req);
  if (b.token) await query("UPDATE auth_sessions SET is_active=false WHERE token=$1", [b.token]);
  json(res, { logged_out: true });
});

addRoute("GET", "/auth/verify/([^/]+)", async (_req, res, matches) => {
  const v = (await query("SELECT * FROM email_verifications WHERE token=$1 AND verified_at IS NULL AND expires_at>NOW()", [matches[1]])).rows[0];
  if (!v) return json(res, { error: "Invalid or expired token" }, 400);
  await query("UPDATE email_verifications SET verified_at=NOW() WHERE id=$1", [v.id]);
  await query("UPDATE accounts_profile SET email_verified=true WHERE id=$1", [v.user_id]);
  json(res, { verified: true });
});

addRoute("POST", "/auth/reset-password", async (req, res) => {
  const b = await body(req);
  if (!b.email) return json(res, { error: "email required" }, 400);
  const user = (await query("SELECT id FROM accounts_profile WHERE email=$1", [b.email])).rows[0];
  if (!user) return json(res, { ok: true }); // don't reveal existence
  const token = randomBytes(32).toString("hex");
  await query("INSERT INTO password_resets (user_id,token) VALUES ($1,$2)", [user.id, token]);
  json(res, { ok: true, reset_token: token, brevo: process.env.BREVO_API_KEY ? "configured" : "not_configured" });
});

addRoute("GET", "/friends/([^/]+)", async (_req, res, matches) => {
  const friends = (await query("SELECT f.friend_id,ap.display_name,ap.role,ap.vip_level FROM friends f JOIN accounts_profile ap ON f.friend_id=ap.id WHERE f.user_id=$1 AND f.status='active'", [matches[1]])).rows;
  const pending = (await query("SELECT fr.*,ap.display_name FROM friend_requests fr JOIN accounts_profile ap ON fr.from_user_id=ap.id WHERE fr.to_user_id=$1 AND fr.status='pending'", [matches[1]])).rows;
  json(res, { friends, pending_requests: pending });
});

addRoute("POST", "/friends/request", async (req, res) => {
  const b = await body(req);
  if (!b.from_user_id || !b.to_user_id) return json(res, { error: "from_user_id and to_user_id required" }, 400);
  const r = await query("INSERT INTO friend_requests (from_user_id,to_user_id) VALUES ($1,$2) ON CONFLICT DO NOTHING RETURNING *", [b.from_user_id, b.to_user_id]);
  json(res, { request: r.rows[0] || { status: "already_pending" } }, 201);
});

addRoute("POST", "/friends/accept", async (req, res) => {
  const b = await body(req);
  if (!b.request_id || !b.user_id) return json(res, { error: "request_id and user_id required" }, 400);
  const rq = (await query("UPDATE friend_requests SET status='accepted' WHERE id=$1 AND to_user_id=$2 AND status='pending' RETURNING *", [b.request_id, b.user_id])).rows[0];
  if (!rq) return json(res, { error: "Request not found" }, 404);
  await query("INSERT INTO friends (user_id,friend_id) VALUES ($1,$2),($2,$1) ON CONFLICT DO NOTHING", [rq.from_user_id, rq.to_user_id]);
  json(res, { accepted: true });
});

addRoute("POST", "/friends/remove", async (req, res) => {
  const b = await body(req);
  await query("DELETE FROM friends WHERE (user_id=$1 AND friend_id=$2) OR (user_id=$2 AND friend_id=$1)", [b.user_id, b.friend_id]);
  json(res, { removed: true });
});

addRoute("POST", "/friends/block", async (req, res) => {
  const b = await body(req);
  await query("DELETE FROM friends WHERE (user_id=$1 AND friend_id=$2) OR (user_id=$2 AND friend_id=$1)", [b.user_id, b.target_id]);
  await query("INSERT INTO friends (user_id,friend_id,status) VALUES ($1,$2,'blocked') ON CONFLICT (user_id,friend_id) DO UPDATE SET status='blocked'", [b.user_id, b.target_id]);
  json(res, { blocked: true });
});

addRoute("POST", "/players/position", async (req, res) => {
  const b = await body(req);
  if (!b.character_id) return json(res, { error: "character_id required" }, 400);
  await query(
    `INSERT INTO player_positions (character_id,user_id,world_id,x,y,z,display_name,vip_level,role,updated_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,NOW())
     ON CONFLICT (character_id) DO UPDATE SET x=$4,y=$5,z=$6,display_name=$7,updated_at=NOW()`,
    [b.character_id, b.user_id||null, KNOWN_UUIDS.WORLD_LIVING, b.x||0, b.y||3, b.z||0, b.display_name||"Hero", b.vip_level||0, b.role||"player"]
  );
  await query("INSERT INTO online_sessions (character_id,user_id,last_heartbeat,is_online) VALUES ($1,$2,NOW(),true) ON CONFLICT (character_id) DO UPDATE SET last_heartbeat=NOW(),is_online=true", [b.character_id, b.user_id||null]);
  json(res, { synced: true });
});

addRoute("GET", "/players/nearby", async (_req, res) => {
  const r = await query(
    `SELECT pp.character_id,pp.display_name,pp.x,pp.y,pp.z,pp.vip_level,pp.role
     FROM player_positions pp JOIN online_sessions os ON pp.character_id=os.character_id
     WHERE os.is_online=true AND os.last_heartbeat > NOW()-INTERVAL '10 seconds' LIMIT 50`
  );
  json(res, { players: r.rows });
});

addRoute("GET", "/players/online", async (_req, res) => {
  const r = await query("SELECT count(*)::int as online FROM online_sessions WHERE is_online=true AND last_heartbeat > NOW()-INTERVAL '10 seconds'");
  json(res, { online: r.rows[0].online });
});

addRoute("POST", "/players/heartbeat", async (req, res) => {
  const b = await body(req);
  if (b.character_id) await query("UPDATE online_sessions SET last_heartbeat=NOW(),is_online=true WHERE character_id=$1", [b.character_id]);
  json(res, { ok: true });
});

addRoute("GET", "/chat/channels", async (_req, res) => {
  json(res, { channels: ["global","local","clan","system","staff","ch1","ch2","ch3","ch4","ch5","ch6","ch7","ch8","ch9","ch10"] });
});

addRoute("POST", "/chat/moderate", async (req, res) => {
  const b = await body(req);
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized" }, 403);
  if (!b.message_id || !b.action) return json(res, { error: "message_id and action required" }, 400);
  await query("UPDATE chat_messages SET moderation_status=$1 WHERE id=$2", [b.action, b.message_id]);
  await query("INSERT INTO moderation_logs (staff_id,target_user_id,action,reason) VALUES ($1::uuid,(SELECT user_id FROM chat_messages WHERE id=$2),$3,$4)", [b.staff_id, b.message_id, "chat_" + b.action, b.reason || ""]);
  json(res, { moderated: true });
});

addRoute("GET", "/chat/rules", async (_req, res) => {
  json(res, { rules: (await query("SELECT * FROM chat_moderation_rules WHERE is_active=true ORDER BY rule_type")).rows });
});

addRoute("POST", "/clans/([^/]+)/rank", async (req, res, matches) => {
  const b = await body(req);
  if (!b.user_id || !b.role) return json(res, { error: "user_id and role required" }, 400);
  await query("UPDATE clan_members SET role=$1 WHERE clan_id=$2 AND user_id=$3", [b.role, matches[1], b.user_id]);
  await query("INSERT INTO clan_logs (clan_id,user_id,action,details) VALUES ($1,$2,'rank_change',$3)", [matches[1], b.user_id, JSON.stringify({new_role: b.role})]);
  json(res, { updated: true });
});

addRoute("GET", "/clans/([^/]+)/logs", async (_req, res, matches) => {
  json(res, { logs: (await query("SELECT cl.*,ap.display_name FROM clan_logs cl LEFT JOIN accounts_profile ap ON cl.user_id=ap.id WHERE cl.clan_id=$1 ORDER BY cl.created_at DESC LIMIT 50", [matches[1]])).rows });
});

addRoute("GET", "/world/state", async (_req, res) => {
  const wid = KNOWN_UUIDS.WORLD_LIVING;
  const time = (await query("SELECT * FROM world_time WHERE world_id = $1", [wid])).rows[0];
  const weather = (await query("SELECT * FROM world_weather WHERE world_id = $1", [wid])).rows[0];
  json(res, { time, weather });
});

addRoute("GET", "/world/time", async (_req, res) => {
  json(res, { time: (await query("SELECT * FROM world_time WHERE world_id = $1", [KNOWN_UUIDS.WORLD_LIVING])).rows[0] });
});

addRoute("GET", "/world/weather", async (_req, res) => {
  json(res, { weather: (await query("SELECT * FROM world_weather WHERE world_id = $1", [KNOWN_UUIDS.WORLD_LIVING])).rows[0] });
});

addRoute("POST", "/admin/force-weather", async (req, res) => {
  const b = await body(req);
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized" }, 403);
  if (!b.state) return json(res, { error: "state required" }, 400);
  await query("UPDATE world_weather SET state=$1, updated_at=NOW() WHERE world_id=$2", [b.state, KNOWN_UUIDS.WORLD_LIVING]);
  json(res, { forced: b.state });
});

addRoute("POST", "/admin/force-time", async (req, res) => {
  const b = await body(req);
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized" }, 403);
  if (b.hour === undefined) return json(res, { error: "hour required" }, 400);
  await query("UPDATE world_time SET hour=$1, updated_at=NOW() WHERE world_id=$2", [b.hour, KNOWN_UUIDS.WORLD_LIVING]);
  json(res, { forced_hour: b.hour });
});

addRoute("GET", "/admin/security-logs", async (req, res) => {
  const url = new URL(req.url || "/", "http://localhost");
  const sid = url.searchParams.get("staff_id");
  if (!await isStaff(sid)) return json(res, { error: "Unauthorized: staff_id required" }, 403);
  json(res, { logs: (await query("SELECT sl.*,ap.display_name FROM security_logs sl LEFT JOIN accounts_profile ap ON sl.user_id=ap.id ORDER BY sl.created_at DESC LIMIT 50")).rows });
});

// ===== PRODUCTION FIXES =====

addRoute("POST", "/characters/([^/]+)/quests/complete", async (req, res, matches) => {
  const b = await body(req);
  if (!b.quest_id) return json(res, { error: "quest_id required" }, 400);
  const r = await query("UPDATE quest_progress SET state='completed', completed_at=NOW(), updated_at=NOW() WHERE character_id=$1 AND quest_id=$2 AND state='active' RETURNING *", [matches[1], b.quest_id]);
  if (!r.rows[0]) return json(res, { error: "Quest not active" }, 400);
  const quest = (await query("SELECT rewards FROM quest_data WHERE id=$1", [b.quest_id])).rows[0];
  if (quest && quest.rewards) {
    const rewards = typeof quest.rewards === "string" ? JSON.parse(quest.rewards) : quest.rewards;
    if (rewards.xp) await query("UPDATE character_stats SET xp=xp+$1, updated_at=NOW() WHERE character_id=$2", [rewards.xp, matches[1]]);
    if (rewards.zorium) {
      await query("UPDATE wallets SET balance=balance+$1, updated_at=NOW() WHERE character_id=$2", [rewards.zorium, matches[1]]);
      await query("UPDATE character_stats SET zorium=zorium+$1, updated_at=NOW() WHERE character_id=$2", [rewards.zorium, matches[1]]);
      const uid = (await query("SELECT account_id FROM characters WHERE id=$1", [matches[1]])).rows[0]?.account_id;
      await query("INSERT INTO zorium_ledger (user_id,character_id,amount,tx_type,source,reason) VALUES ($1,$2,$3,'quest_reward','system','Quest completion')", [uid, matches[1], rewards.zorium]);
    }
  }
  await query("INSERT INTO score_entries (user_id,character_id,score_type,amount,source) SELECT c.account_id,c.id,'quest',100,'quest_complete' FROM characters c WHERE c.id=$1", [matches[1]]);
  await query("INSERT INTO ranking_entries (user_id,character_id,ranking_type,score) SELECT c.account_id,c.id,'quests',1 FROM characters c WHERE c.id=$1 ON CONFLICT DO NOTHING", [matches[1]]);
  json(res, { completed: true, rewards: quest?.rewards });
});

addRoute("POST", "/characters/([^/]+)/power-rush/activate", async (req, res, matches) => {
  const b = await body(req);
  if (!b.power_rush_id) return json(res, { error: "power_rush_id required" }, 400);
  const pr = (await query("SELECT * FROM power_rush_items WHERE id=$1", [b.power_rush_id])).rows[0];
  if (!pr) return json(res, { error: "Power Rush not found" }, 404);
  const cost = parseFloat(pr.cost_zorium);
  const w = await query("SELECT * FROM wallets WHERE character_id=$1", [matches[1]]);
  if (!w.rows[0] || parseFloat(w.rows[0].balance) < cost) return json(res, { error: "Insufficient zorium", cost }, 400);
  await query("UPDATE wallets SET balance=balance-$1, updated_at=NOW() WHERE character_id=$2", [cost, matches[1]]);
  await query("UPDATE character_stats SET zorium=zorium-$1, updated_at=NOW() WHERE character_id=$2", [cost, matches[1]]);
  const uid = (await query("SELECT account_id FROM characters WHERE id=$1", [matches[1]])).rows[0]?.account_id;
  await query("INSERT INTO zorium_ledger (user_id,character_id,amount,tx_type,source,reason) VALUES ($1,$2,$3,'shop_purchase','system','Power Rush activation')", [uid, matches[1], -cost]);
  const expires = new Date(Date.now() + pr.duration_seconds * 1000).toISOString();
  await query("INSERT INTO user_power_rush (user_id,character_id,power_rush_id,expires_at) VALUES ($1,$2,$3,$4)", [uid, matches[1], b.power_rush_id, expires]);
  json(res, { activated: true, expires_at: expires, effect: pr.effects });
});

// ===== LORE ENGINE =====

addRoute("GET", "/lore/character/([^/]+)", async (_req, res, matches) => {
  const bio = (await query("SELECT * FROM character_biographies WHERE character_id=$1", [matches[1]])).rows[0];
  const timeline = (await query("SELECT * FROM character_timeline WHERE character_id=$1 ORDER BY created_at DESC LIMIT 20", [matches[1]])).rows;
  const rep = (await query("SELECT * FROM character_reputation WHERE character_id=$1", [matches[1]])).rows;
  const titles = (await query("SELECT * FROM character_titles_earned WHERE character_id=$1", [matches[1]])).rows;
  json(res, { bio, timeline, reputation: rep, titles });
});

addRoute("GET", "/lore/clan/([^/]+)", async (_req, res, matches) => {
  const lore = (await query("SELECT * FROM clan_lore WHERE clan_id=$1", [matches[1]])).rows[0];
  const chronicles = (await query("SELECT * FROM clan_chronicles WHERE clan_id=$1 ORDER BY created_at DESC LIMIT 20", [matches[1]])).rows;
  json(res, { lore, chronicles });
});

addRoute("GET", "/lore/kingdom/([^/]+)", async (_req, res, matches) => {
  json(res, { lore: (await query("SELECT * FROM kingdom_lore WHERE kingdom_id=$1", [matches[1]])).rows[0] });
});

addRoute("GET", "/lore/territory/([^/]+)", async (_req, res, matches) => {
  json(res, { lore: (await query("SELECT * FROM territory_lore WHERE territory_id=$1", [matches[1]])).rows[0] });
});

addRoute("GET", "/lore/npc/([^/]+)", async (_req, res, matches) => {
  const name = decodeURIComponent(matches[1]).replace(/\+/g, " ");
  json(res, { npc: (await query("SELECT * FROM npc_lore WHERE npc_name ILIKE $1", ["%" + name + "%"])).rows[0] || null });
});

addRoute("GET", "/lore/chronicles", async (_req, res) => {
  json(res, { chronicles: (await query("SELECT * FROM world_chronicles WHERE is_public=true ORDER BY created_at DESC LIMIT 20")).rows });
});

addRoute("GET", "/characters/([^/]+)/biography", async (_req, res, matches) => {
  await query("INSERT INTO character_biographies (character_id) VALUES ($1) ON CONFLICT DO NOTHING", [matches[1]]);
  await query("INSERT INTO character_timeline (character_id, event_type, title) VALUES ($1, 'birth', 'Despertou no Vale') ON CONFLICT DO NOTHING", [matches[1]]);
  await query("INSERT INTO character_reputation (character_id, target_type, target_id, reputation_score) VALUES ($1, 'world', 'world', 0) ON CONFLICT DO NOTHING", [matches[1]]);
  const bio = (await query("SELECT * FROM character_biographies WHERE character_id=$1", [matches[1]])).rows[0];
  json(res, { biography: bio });
});

// ===== WAR KINGDOM =====

addRoute("GET", "/servers", async (_req, res) => {
  json(res, { servers: (await query("SELECT * FROM game_servers ORDER BY name")).rows });
});

addRoute("GET", "/classes", async (_req, res) => {
  json(res, { classes: (await query("SELECT * FROM hero_classes ORDER BY name")).rows });
});

addRoute("GET", "/classes/([^/]+)", async (_req, res, matches) => {
  const c = (await query("SELECT * FROM hero_classes WHERE id = $1", [matches[1]])).rows[0];
  json(res, { class: c || null });
});

addRoute("GET", "/territories/map", async (_req, res) => {
  json(res, { territories: (await query("SELECT * FROM territory_map ORDER BY name")).rows });
});

addRoute("GET", "/kingdoms/list", async (_req, res) => {
  json(res, { kingdoms: (await query("SELECT * FROM kingdom_registry ORDER BY level DESC, name")).rows });
});

addRoute("POST", "/kingdoms/create", async (req, res) => {
  const b = await body(req);
  if (!b.name || !b.tag || !b.ruler_user_id) return json(res, { error: "name, tag, ruler_user_id required" }, 400);
  const r = await query("INSERT INTO kingdom_registry (name,tag,ruler_user_id,origin_clan_id) VALUES ($1,$2,$3,$4) RETURNING *", [b.name, b.tag, b.ruler_user_id, b.origin_clan_id || null]);
  await query("INSERT INTO kingdom_members (kingdom_id,user_id,rank) VALUES ($1,$2,'king')", [r.rows[0].id, b.ruler_user_id]);
  json(res, { kingdom: r.rows[0] }, 201);
});

addRoute("GET", "/kingdoms/([^/]+)/members", async (_req, res, matches) => {
  json(res, { members: (await query("SELECT km.*,ap.display_name FROM kingdom_members km JOIN accounts_profile ap ON km.user_id=ap.id WHERE km.kingdom_id=$1 ORDER BY km.rank", [matches[1]])).rows });
});

addRoute("POST", "/war/declaration", async (req, res) => {
  const b = await body(req);
  if (!await isStaff(b.declared_by)) return json(res, { error: "Unauthorized: staff required for war declaration" }, 403);
  if (!b.attacker_type || !b.attacker_id || !b.defender_type || !b.defender_id) return json(res, { error: "attacker and defender required" }, 400);
  const r = await query("INSERT INTO war_declarations (attacker_type,attacker_id,defender_type,defender_id,declared_by,reason) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *", [b.attacker_type, b.attacker_id, b.defender_type, b.defender_id, b.declared_by, b.reason || ""]);
  await query("INSERT INTO war_logs (war_id,actor_id,action) VALUES ($1,$2,'declared')", [r.rows[0].id, b.declared_by]);
  json(res, { war: r.rows[0] }, 201);
});

addRoute("GET", "/war/([^/]+)", async (_req, res, matches) => {
  json(res, { war: (await query("SELECT * FROM war_declarations WHERE id = $1", [matches[1]])).rows[0] || null });
});

addRoute("GET", "/war/([^/]+)/participants", async (_req, res, matches) => {
  json(res, { participants: (await query("SELECT wp.*,c.character_name FROM war_participants wp JOIN characters c ON wp.character_id=c.id WHERE wp.war_id=$1", [matches[1]])).rows });
});

addRoute("GET", "/rankings/war", async (_req, res) => {
  json(res, { rankings: (await query("SELECT * FROM war_ranking_entries ORDER BY score DESC LIMIT 50")).rows });
});

addRoute("GET", "/characters/([^/]+)/allegiance", async (_req, res, matches) => {
  await query("INSERT INTO character_origins (character_id) VALUES ($1) ON CONFLICT DO NOTHING", [matches[1]]);
  const origin = (await query("SELECT co.*,hc.name as class_name FROM character_origins co LEFT JOIN hero_classes hc ON co.class_id=hc.id WHERE co.character_id=$1", [matches[1]])).rows[0];
  const allegiance = (await query("SELECT * FROM character_allegiances WHERE character_id=$1", [matches[1]])).rows[0];
  json(res, { origin, allegiance });
});

addRoute("POST", "/characters/([^/]+)/class", async (req, res, matches) => {
  const b = await body(req);
  if (!b.class_id) return json(res, { error: "class_id required" }, 400);
  await query("INSERT INTO character_origins (character_id, class_id) VALUES ($1,$2) ON CONFLICT (character_id) DO UPDATE SET class_id=$2", [matches[1], b.class_id]);
  json(res, { assigned: true });
});

addRoute("GET", "/troops/types", async (_req, res) => {
  json(res, { troop_types: (await query("SELECT * FROM troop_types ORDER BY category, name")).rows });
});

// ===== TWITCH + AI + LIVE WINDOWS =====

addRoute("GET", "/twitch/status", async (req, res) => {
  const b = await body(req).catch(() => ({})); const uid = b.user_id as string;
  if (uid) { const link = (await query("SELECT twitch_login, status, expires_at FROM twitch_account_links WHERE user_id=$1", [uid])).rows[0]; return json(res, { linked: !!link, ...link, mode: process.env.TWITCH_CLIENT_ID ? "oauth_ready" : "not_configured" }); }
  json(res, { linked: false, mode: process.env.TWITCH_CLIENT_ID ? "oauth_ready" : "not_configured" });
});

addRoute("POST", "/twitch/link", async (req, res) => {
  const b = await body(req); if (!b.user_id || !b.twitch_user_id || !b.access_token) return json(res, { error: "user_id, twitch_user_id, access_token required" }, 400);
  await query("INSERT INTO twitch_account_links (user_id,twitch_user_id,twitch_login,twitch_display_name,access_token_encrypted,scopes,expires_at) VALUES ($1,$2,$3,$4,$5,$6,NOW()+INTERVAL'4 hours') ON CONFLICT (user_id) DO UPDATE SET access_token_encrypted=$5,scopes=$6,expires_at=NOW()+INTERVAL'4 hours'", [b.user_id, b.twitch_user_id, b.twitch_login||"", b.twitch_display_name||"", b.access_token, b.scopes||[]]);
  json(res, { linked: true });
});

addRoute("GET", "/twitch/overlay/([^/]+)", async (_req, res, matches) => {
  const overlay = (await query("SELECT * FROM streamer_overlays WHERE overlay_token=$1 AND is_active=true", [matches[1]])).rows[0];
  json(res, { overlay: overlay || null });
});

addRoute("POST", "/twitch/overlay/create", async (req, res) => {
  const b = await body(req); if (!b.user_id) return json(res, { error: "user_id required" }, 400);
  const token = require("crypto").randomBytes(16).toString("hex");
  const r = await query("INSERT INTO streamer_overlays (user_id, overlay_token, scene_type) VALUES ($1,$2,$3) RETURNING *", [b.user_id, token, b.scene_type||"player_profile"]);
  json(res, { overlay: r.rows[0] });
});

addRoute("POST", "/ai/transcription/start", async (req, res) => {
  const b = await body(req);
  const r = await query("INSERT INTO ai_transcription_sessions (user_id, character_id, started_at, status) VALUES ($1,$2,NOW(),'active') RETURNING *", [b.user_id||null, b.character_id||null]);
  json(res, { session: r.rows[0], mode: process.env.AI_API_KEY ? "ai" : "not_configured" });
});

addRoute("POST", "/ai/coaching/start", async (req, res) => {
  const b = await body(req);
  const r = await query("INSERT INTO ai_coaching_sessions (user_id, character_id, coaching_type, context, started_at) VALUES ($1,$2,$3,$4,NOW()) RETURNING *", [b.user_id||null, b.character_id||null, b.coaching_type||"profile", JSON.stringify(b.context||{})]);
  json(res, { session: r.rows[0], mode: process.env.AI_API_KEY ? "ai" : "not_configured" });
});

addRoute("GET", "/live-windows/products", async (_req, res) => {
  json(res, { products: (await query("SELECT * FROM live_window_products")).rows, mode: process.env.STRIPE_SECRET_KEY ? "live" : "sandbox" });
});

addRoute("POST", "/live-windows/create", async (req, res) => {
  const b = await body(req); if (!b.user_id || !b.product_id) return json(res, { error: "user_id and product_id required" }, 400);
  const p = (await query("SELECT * FROM live_window_products WHERE id=$1", [b.product_id])).rows[0]; if (!p) return json(res, { error: "Product not found" }, 404);
  const r = await query("INSERT INTO live_windows (user_id, window_type, status, starts_at, ends_at, duration_minutes, max_streams) VALUES ($1,$2,'pending_payment',NOW(),NOW()+($3||' minutes')::interval,$3,$4) RETURNING *", [b.user_id, p.window_type, p.duration_minutes, p.max_streams]);
  json(res, { window: r.rows[0], mode: process.env.STRIPE_SECRET_KEY ? "live" : "sandbox" });
});

addRoute("GET", "/live-windows/me", async (req, res) => {
  const b = await body(req).catch(() => ({}));
  json(res, { windows: (await query("SELECT * FROM live_windows WHERE user_id=$1 ORDER BY created_at DESC", [b.user_id])).rows, mode: process.env.STRIPE_SECRET_KEY ? "live" : "sandbox" });
});

// ===== PUBLIC API v1 + LAUNCHER =====

async function checkApiKey(req: IncomingMessage): Promise<{ ok: boolean; clientId?: string }> {
  const auth = req.headers["authorization"] as string || "";
  if (!auth.startsWith("Bearer ")) return { ok: true }; // allow unauthenticated for public endpoints
  const key = auth.slice(7);
  const clients = (await query("SELECT * FROM public_api_clients WHERE status = 'active'")).rows;
  for (const client of clients) {
    const hash = createHash("sha256").update(key).digest("hex");
    if (client.client_secret_hash === hash || key === client.client_secret_hash) {
      await query("INSERT INTO public_api_usage_logs (client_id, endpoint, request_ip) VALUES ($1,$2,$3)", [client.id, req.url || "/", (req.headers["x-forwarded-for"] as string) || "unknown"]);
      return { ok: true, clientId: client.id };
    }
  }
  return { ok: false };
}

addRoute("GET", "/api/public/v1/health", async (req, res) => {
  const auth = await checkApiKey(req);
  json(res, { status: "ok", mode: auth.clientId ? "authenticated" : "public", version: "1.0.0" });
});

addRoute("GET", "/api/public/v1/world/state", async (_req, res) => {
  const wid = KNOWN_UUIDS.WORLD_LIVING;
  const time = (await query("SELECT hour, day, month, year, season FROM world_time WHERE world_id = $1", [wid])).rows[0];
  const weather = (await query("SELECT state, temperature, humidity, wind_speed, visibility FROM world_weather WHERE world_id = $1", [wid])).rows[0];
  json(res, { time, weather });
});

addRoute("GET", "/api/public/v1/characters/([^/]+)/profile", async (_req, res, matches) => {
  const c = (await query("SELECT c.character_name, cs.level, cs.xp, cs.zorium, ap.display_name, ap.role, ap.vip_level, co.origin_name, hc.name as class_name FROM characters c JOIN character_stats cs ON cs.character_id=c.id JOIN accounts_profile ap ON ap.id=c.account_id LEFT JOIN character_origins co ON co.character_id=c.id LEFT JOIN hero_classes hc ON co.class_id=hc.id WHERE c.id=$1", [matches[1]])).rows[0];
  const rep = (await query("SELECT reputation_score FROM character_reputation WHERE character_id=$1 AND target_type='world'", [matches[1]])).rows[0];
  json(res, { character: { ...c, reputation: rep?.reputation_score || 0 } });
});

addRoute("GET", "/api/public/v1/rankings/global", async (_req, res) => {
  json(res, { rankings: (await query("SELECT re.*, ap.display_name FROM ranking_entries re JOIN accounts_profile ap ON re.user_id=ap.id ORDER BY re.score DESC LIMIT 50")).rows });
});

addRoute("GET", "/api/public/v1/lore/characters/([^/]+)", async (_req, res, matches) => {
  const bio = (await query("SELECT origin_name, birth_homeland, public_biography FROM character_biographies WHERE character_id=$1", [matches[1]])).rows[0];
  const timeline = (await query("SELECT event_type, title, description, created_at FROM character_timeline WHERE character_id=$1 ORDER BY created_at DESC LIMIT 10", [matches[1]])).rows;
  json(res, { bio, timeline });
});

addRoute("GET", "/api/launcher/status", async (_req, res) => {
  const online = (await query("SELECT count(*)::int as online FROM online_sessions WHERE is_online=true AND last_heartbeat > NOW()-INTERVAL '10 seconds'")).rows[0].online;
  const m = (await query("SELECT * FROM scheduled_maintenance WHERE status IN ('scheduled','active') ORDER BY starts_at LIMIT 1")).rows[0];
  json(res, { server: "online", players_online: online, maintenance: m || null, game_version: "3.2.0-lore", server_name: "Vale Cinzento" });
});

addRoute("GET", "/api/launcher/manifest", async (_req, res) => {
  const m = (await query("SELECT * FROM launcher_manifests ORDER BY published_at DESC LIMIT 1")).rows[0];
  json(res, { manifest: m ? m.manifest_json : { files: [] }, game_version: "4.3.2", launcher_version: "0.5.0", force_update: true, backend_min_version: "2.0.0" });
});

addRoute("GET", "/api/launcher/news", async (_req, res) => {
  const ann = (await query("SELECT * FROM server_announcements WHERE expires_at > NOW() ORDER BY priority DESC LIMIT 5")).rows;
  json(res, { news: ann });
});

addRoute("POST", "/api/launcher/update-report", async (req, res) => {
  const b = await body(req);
  if (b.user_id) {
    await query("INSERT INTO launcher_logs (user_id, character_id, platform, action, details) VALUES ($1,$2,$3,$4,$5)", [b.user_id, b.character_id||null, b.platform||"unknown", b.action||"start", JSON.stringify({version: b.version, status: b.status})]);
  }
  json(res, { received: true });
});

addRoute("POST", "/api/launcher/repair-report", async (req, res) => {
  const b = await body(req);
  if (b.user_id) {
    await query("INSERT INTO launcher_logs (user_id, platform, action, details) VALUES ($1,$2,'repair',$3)", [b.user_id, b.platform||"unknown", JSON.stringify({success: b.success, files_checked: b.files_checked||0})]);
  }
  json(res, { received: true });
});

// ===== COMBAT VFX (dev only) =====

addRoute("GET", "/combat-vfx/config", async (req, res) => {
  const b = await body(req).catch(() => ({}));
  if (!b.user_id) return json(res, { config: null });
  const cfg = (await query("SELECT * FROM combat_vfx_config WHERE user_id = $1", [b.user_id])).rows[0];
  json(res, { config: cfg || { brutality_level: "dark", particle_quality: "medium" } });
});

addRoute("PUT", "/combat-vfx/config", async (req, res) => {
  const b = await body(req);
  if (!b.user_id) return json(res, { error: "user_id required" }, 400);
  await query("INSERT INTO combat_vfx_config (user_id, brutality_level) VALUES ($1,$2) ON CONFLICT (user_id) DO UPDATE SET brutality_level=$2, updated_at=NOW()", [b.user_id, b.brutality_level || "dark"]);
  json(res, { updated: true });
});

addRoute("GET", "/combat-vfx/presets", async (_req, res) => {
  json(res, { presets: (await query("SELECT * FROM combat_effect_presets ORDER BY name")).rows });
});

addRoute("POST", "/combat-vfx/event/dev", async (req, res) => {
  const b = await body(req);
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized: staff required for dev VFX events" }, 403);
  await query("INSERT INTO combat_visual_logs (event_type, attacker_id, target_id, position, synced) VALUES ($1,$2,$3,$4,false)", [b.event_type || "dev_test", b.attacker_id, b.target_id, JSON.stringify(b.position || {})]);
  json(res, { logged: true });
});

addRoute("POST", "/combat-vfx/event/log", async (req, res) => {
  const b = await body(req);
  await query("INSERT INTO combat_visual_logs (event_type, attacker_id, target_id, position, synced) VALUES ($1,$2,$3,$4,false)", [b.event_type || "combat", b.attacker_id, b.target_id, JSON.stringify(b.position || {})]);
  json(res, { logged: true });
});

// ===== ZERO TRUST =====

addRoute("POST", "/launcher/register-device", async (req, res) => {
  const b = await body(req);
  const uid = b.user_id as string || null;
  const instId = (b.installation_id as string) || ("DW-" + Date.now());
  const hash = (b.device_id_hash as string) || instId;
  const ip = (req.headers["x-forwarded-for"] as string) || "unknown";
  const r = await query("INSERT INTO device_profiles (user_id, installation_id, device_id_hash, os_name, ip_first, ip_last) VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT DO NOTHING RETURNING *", [uid, instId, hash, b.os || "unknown", ip, ip]);
  const device = r.rows[0] || (await query("SELECT * FROM device_profiles WHERE installation_id = $1", [instId])).rows[0];
  json(res, { device_id: device.id, trust_score: device.trust_score });
});

addRoute("GET", "/launcher/trust/:deviceId", async (_req, res, matches) => {
  const d = (await query("SELECT * FROM device_profiles WHERE id = $1 OR installation_id = $1", [matches[1]])).rows[0];
  json(res, { trust_score: d?.trust_score || 500, blacklisted: d?.is_blacklisted || false });
});

addRoute("GET", "/admin/trust-dashboard", async (req, res) => {
  const b = await body(req).catch(() => ({}));
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized" }, 403);
  const avg = (await query("SELECT AVG(trust_score)::int as avg FROM trust_profiles")).rows[0]?.avg || 500;
  const low = (await query("SELECT count(*) FROM trust_profiles WHERE trust_score < 300")).rows[0]?.count || 0;
  const top = (await query("SELECT tp.*, ap.display_name FROM trust_profiles tp JOIN accounts_profile ap ON tp.user_id = ap.id ORDER BY tp.trust_score ASC LIMIT 10")).rows;
  json(res, { avg_trust: avg, low_trust_count: parseInt(low), top_low_trust: top });
});

addRoute("GET", "/admin/fraud-dashboard", async (req, res) => {
  const b = await body(req).catch(() => ({}));
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized" }, 403);
  const cats = (await query("SELECT category, count(*) as total FROM fraud_events WHERE resolved = false GROUP BY category ORDER BY total DESC")).rows;
  const total = (await query("SELECT count(*) FROM fraud_events WHERE resolved = false")).rows[0]?.count || 0;
  json(res, { total_unresolved: parseInt(total), by_category: cats });
});

addRoute("GET", "/admin/security-dashboard", async (req, res) => {
  const b = await body(req).catch(() => ({}));
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized" }, 403);
  const online = (await query("SELECT count(*)::int as online FROM online_sessions WHERE is_online = true AND last_heartbeat > NOW() - INTERVAL '10 seconds'")).rows[0].online;
  const alerts = (await query("SELECT count(*) FROM fraud_events WHERE resolved = false AND severity IN ('high','critical','blocker')")).rows[0]?.count || 0;
  const cheats = (await query("SELECT count(*) FROM anti_cheat_events WHERE created_at > NOW() - INTERVAL '24 hours'")).rows[0]?.count || 0;
  json(res, { online_players: online, high_alerts: parseInt(alerts), cheats_24h: parseInt(cheats) });
});

addRoute("GET", "/admin/cheat-events", async (req, res) => {
  const b = await body(req).catch(() => ({}));
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized" }, 403);
  json(res, { events: (await query("SELECT ace.*, ap.display_name FROM anti_cheat_events ace LEFT JOIN accounts_profile ap ON ace.user_id = ap.id ORDER BY ace.created_at DESC LIMIT 50")).rows });
});

addRoute("POST", "/admin/trust/adjust", async (req, res) => {
  const b = await body(req);
  if (!await isStaff(b.staff_id)) return json(res, { error: "Unauthorized" }, 403);
  if (!b.user_id || b.delta === undefined) return json(res, { error: "user_id and delta required" }, 400);
  await query("UPDATE trust_profiles SET trust_score = GREATEST(0, LEAST(1000, trust_score + $1)), updated_at = NOW() WHERE user_id = $2", [parseInt(b.delta as string) || 0, b.user_id]);
  await query("INSERT INTO trust_events (user_id, event_type, score_delta, reason) VALUES ($1,'admin_adjust',$2,$3)", [b.user_id, parseInt(b.delta as string) || 0, b.reason || "Admin adjustment"]);
  json(res, { adjusted: true });
});

// ===== ROUTER =====
export async function handleRequest(req: IncomingMessage, res: ServerResponse) {
  if (req.method === "OPTIONS") { res.writeHead(204, { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS", "Access-Control-Allow-Headers": "Content-Type,Authorization" }); res.end(); return; }
  const url = req.url?.split("?")[0] || "/";
  for (const route of routes) { const matches = url.match(route.path); if (matches && req.method === route.method) { try { await route.handler(req, res, matches); } catch (e: any) { console.error("[API]", e); json(res, { error: e.message }, 500); } return; } }
  json(res, { error: "not_found", path: url }, 404);
}
