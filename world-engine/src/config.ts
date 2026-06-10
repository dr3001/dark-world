import { readFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

function loadEnvFile() {
  const envPath = resolve(__dirname, "../../.env");
  try {
    const content = readFileSync(envPath, "utf-8");
    for (const line of content.split("\n")) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) continue;
      const eqIdx = trimmed.indexOf("=");
      if (eqIdx === -1) continue;
      const key = trimmed.slice(0, eqIdx).trim();
      const val = trimmed.slice(eqIdx + 1).trim();
      if (!process.env[key]) process.env[key] = val;
    }
  } catch {
    // Docker: env vars already set by docker compose, no .env file needed
  }
}

loadEnvFile();

export const config = {
  port: parseInt(process.env.ENGINE_PORT || "9000"),
  tickInterval: parseInt(process.env.ENGINE_TICK_INTERVAL || "2000"),
  db: {
    host: process.env.DB_HOST || "localhost",
    port: parseInt(process.env.DB_PORT || "5433"),
    user: process.env.DB_USER || "darkworld_admin",
    password: process.env.DB_PASSWORD || "",
    database: process.env.DB_NAME || "darkworld",
  },
  redis: {
    host: process.env.REDIS_HOST || "localhost",
    port: parseInt(process.env.REDIS_PORT || "6380"),
    password: process.env.REDIS_PASSWORD || "",
  },
  afterlife: {
    testMinutes: parseInt(process.env.AFTERLIFE_TEST_MINUTES || "5"),
  },
  logLevel: process.env.LOG_LEVEL || "info",
};

export const KNOWN_UUIDS = {
  WORLD_LIVING: "a0000000-0000-0000-0000-000000000001",
  WORLD_FROZEN: "a0000000-0000-0000-0000-000000000002",
  WORLD_SHADOW: "a0000000-0000-0000-0000-000000000003",
  TERRITORY_VALE: "b0000000-0000-0000-0000-000000000010",
  FACTION_REINO: "b0000000-0000-0000-0000-000000000020",
  FACTION_LEGIAO: "b0000000-0000-0000-0000-000000000021",
  DRAGON_VORAK: "b0000000-0000-0000-0000-000000000050",
};
