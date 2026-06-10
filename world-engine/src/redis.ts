import Redis from "ioredis";
import { config } from "./config.js";

const redis = new Redis({
  host: config.redis.host,
  port: config.redis.port,
  password: config.redis.password || undefined,
  retryStrategy: (times) => Math.min(times * 500, 5000),
  maxRetriesPerRequest: 3,
});

redis.on("connect", () => console.log("[Redis] Conectado"));
redis.on("error", (err) => console.error("[Redis] Erro:", err.message));

export async function testConnection(): Promise<boolean> {
  try {
    const pong = await redis.ping();
    console.log(`[Redis] ${pong}`);
    return pong === "PONG";
  } catch (err: any) {
    console.error(`[Redis] Falha: ${err.message}`);
    return false;
  }
}

export default redis;
