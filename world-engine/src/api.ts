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

// ===== ROUTER =====
export async function handleRequest(req: IncomingMessage, res: ServerResponse) {
  if (req.method === "OPTIONS") { res.writeHead(204, { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET,POST,OPTIONS", "Access-Control-Allow-Headers": "Content-Type,Authorization" }); res.end(); return; }
  const url = req.url || "/";
  for (const route of routes) { const matches = url.match(route.path); if (matches && req.method === route.method) { await route.handler(req, res, matches); return; } }
  json(res, { error: "not_found", path: url }, 404);
}
