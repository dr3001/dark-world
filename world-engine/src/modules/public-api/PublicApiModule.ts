import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";
import { randomBytes, scryptSync } from "crypto";

const rateLimitStore = new Map<string, { count: number; reset: number }>();

export class PublicApiModule extends WorldEngineModule {
  name = "PublicApiModule";
  override async initialize() { console.log("[PublicApiModule] Initialized — API key auth + rate limiting"); }

  async createClient(name: string, ownerUserId: string, scopes: string[] = ["read:profile"]) {
    const secret = randomBytes(32).toString("hex");
    const hash = scryptSync(secret, "darkworld", 64).toString("hex");
    const client = (await query("INSERT INTO public_api_clients (name, owner_user_id, client_secret_hash) VALUES ($1,$2,$3) RETURNING id,name", [name, ownerUserId, hash])).rows[0];
    for (const scope of scopes) {
      await query("INSERT INTO public_api_scopes (client_id, scope) VALUES ($1,$2) ON CONFLICT DO NOTHING", [client.id, scope]);
    }
    await query("INSERT INTO public_api_rate_limits (client_id, scope, max_requests) VALUES ($1,'default',60) ON CONFLICT DO NOTHING", [client.id]);
    return { client_id: client.id, client_name: client.name, client_secret: secret, scopes };
  }

  async validateApiKey(apiKey: string): Promise<{ valid: boolean; clientId?: string; scopes?: string[] }> {
    const clients = (await query("SELECT * FROM public_api_clients WHERE status = 'active'")).rows;
    for (const client of clients) {
      const [salt, hash] = client.client_secret_hash.includes(":") ? client.client_secret_hash.split(":") : ["", ""];
      const testHash = salt ? scryptSync(apiKey, salt, 64).toString("hex") : "";
      if (hash === testHash || apiKey === client.client_secret_hash) {
        const scopes = (await query("SELECT scope FROM public_api_scopes WHERE client_id = $1", [client.id])).rows.map((r: any) => r.scope);
        await query("INSERT INTO public_api_usage_logs (client_id, endpoint, response_code, request_ip) VALUES ($1,'auth_check',200,'0.0.0.0')", [client.id]);
        return { valid: true, clientId: client.id, scopes };
      }
    }
    return { valid: false };
  }

  checkRateLimit(clientId: string): boolean {
    const now = Date.now();
    const key = "rl:" + clientId;
    const entry = rateLimitStore.get(key);
    if (!entry || now > entry.reset) {
      rateLimitStore.set(key, { count: 1, reset: now + 60000 });
      return true;
    }
    if (entry.count >= 60) return false;
    entry.count++;
    return true;
  }
}
