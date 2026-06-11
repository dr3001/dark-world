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
  json(res, { status: "ok", uptime: process.uptime(), version: "0.3.0", modules: ["DeathModule","AfterlifeModule","DragonModule","TerritoryModule","FactionModule","AuditModule"] });
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
  await query("INSERT INTO transactions (from_wallet_id, amount, tx_type, description) VALUES ($1,$2,'purchase','heal')", [w.rows[0].id, cost]);
  await query("UPDATE character_stats SET hp = max_hp, updated_at = NOW() WHERE character_id = $1", [cid]);
  const stats = await query("SELECT hp, max_hp, zorium FROM character_stats WHERE character_id = $1", [cid]);
  json(res, { healed: true, cost, stats: stats.rows[0] });
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

// ===== ROUTER =====
export async function handleRequest(req: IncomingMessage, res: ServerResponse) {
  if (req.method === "OPTIONS") { res.writeHead(204, { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS", "Access-Control-Allow-Headers": "Content-Type,Authorization" }); res.end(); return; }
  const url = req.url?.split("?")[0] || "/";
  for (const route of routes) { const matches = url.match(route.path); if (matches && req.method === route.method) { try { await route.handler(req, res, matches); } catch (e: any) { console.error("[API]", e); json(res, { error: e.message }, 500); } return; } }
  json(res, { error: "not_found", path: url }, 404);
}
