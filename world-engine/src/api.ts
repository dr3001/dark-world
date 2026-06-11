import { IncomingMessage, ServerResponse } from "http";
import { query } from "./db.js";
import { config, KNOWN_UUIDS } from "./config.js";

interface Route {
  method: string;
  path: RegExp;
  handler: (req: IncomingMessage, res: ServerResponse, matches: RegExpMatchArray) => Promise<void>;
}

const routes: Route[] = [];
function addRoute(method: string, pattern: string, handler: Route["handler"]) { routes.push({ method, path: new RegExp(`^${pattern}$`), handler }); }
function json(res: ServerResponse, data: unknown, status = 200) { res.writeHead(status, { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }); res.end(JSON.stringify(data)); }
function body(req: IncomingMessage): Promise<Record<string, unknown>> { return new Promise((resolve) => { let data = ""; req.on("data", (chunk) => (data += chunk)); req.on("end", () => { try { resolve(JSON.parse(data)); } catch { resolve({}); } }); }); }

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
  json(res, { status: "ok", uptime: process.uptime(), version: "0.7.0", modules: ["DeathModule","AfterlifeModule","DragonModule","TerritoryModule","FactionModule","AuditModule","CharacterStatsModule","ItemModule","InventoryModule","EquipmentModule","WalletModule","QuestModule","NPCModule","CombatPrepModule","LootModule"] });
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

addRoute("POST", "/chat/send", async (req, res) => {
  const b = await body(req);
  if (!b.message) return json(res, { error: "message required" }, 400);
  const r = await query("INSERT INTO chat_messages (user_id, character_id, display_name, vip_level, role, message, channel) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *",
    [b.user_id || null, b.character_id || null, b.display_name || "Anonimo", b.vip_level || 0, b.role || "player", b.message, b.channel || "global"]);
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
  if (!b.user_id || !b.ban_type) return json(res, { error: "user_id and ban_type required" }, 400);
  await query("INSERT INTO ban_records (user_id, staff_id, ban_type, reason, expires_at) VALUES ($1,$2,$3,$4,$5)", [b.user_id, b.staff_id || null, b.ban_type, b.reason || "", b.expires_at || null]);
  await query("UPDATE accounts_profile SET is_banned = true, status = 'banned' WHERE id = $1", [b.user_id]);
  json(res, { banned: true });
});

addRoute("POST", "/admin/unban", async (req, res) => {
  const b = await body(req);
  if (!b.user_id) return json(res, { error: "user_id required" }, 400);
  await query("UPDATE ban_records SET is_active = false WHERE user_id = $1", [b.user_id]);
  await query("UPDATE accounts_profile SET is_banned = false, status = 'active' WHERE id = $1", [b.user_id]);
  json(res, { unbanned: true });
});

addRoute("POST", "/admin/announce", async (req, res) => {
  const b = await body(req);
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
  const msg = (b.message as string) || "";
  const charId = (b.character_id as string) || "";
  const fallbacks: Record<string, string> = { blacksmith:"Posso forjar armas.", healer:"Posso curar feridas.", guard:"Mantenha-se atento.", merchant:"Tenho mercadorias.", villager:"A vida era tranquila.", guardian:"Vorak voltou." };
  json(res, { reply: fallbacks[npcRole] || "...", mode: process.env.AI_API_KEY ? "ai" : "static" });
});

addRoute("GET", "/wallet/([^/]+)/ledger", async (_req, res, matches) => {
  const r = await query("SELECT * FROM zorium_ledger WHERE character_id = $1 ORDER BY created_at DESC LIMIT 50", [matches[1]]);
  json(res, { ledger: r.rows });
});

// ===== ROUTER =====
export async function handleRequest(req: IncomingMessage, res: ServerResponse) {
  if (req.method === "OPTIONS") { res.writeHead(204, { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS", "Access-Control-Allow-Headers": "Content-Type,Authorization" }); res.end(); return; }
  const url = req.url?.split("?")[0] || "/";
  for (const route of routes) { const matches = url.match(route.path); if (matches && req.method === route.method) { try { await route.handler(req, res, matches); } catch (e: any) { console.error("[API]", e); json(res, { error: e.message }, 500); } return; } }
  json(res, { error: "not_found", path: url }, 404);
}
