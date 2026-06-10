import pg from "pg";
import { config } from "./config.js";

const pool = new pg.Pool({
  host: config.db.host,
  port: config.db.port,
  user: config.db.user,
  password: config.db.password,
  database: config.db.database,
  max: 10,
  idleTimeoutMillis: 30000,
});

pool.on("error", (err) => {
  console.error("[DB] Pool error:", err.message);
});

export async function query(text: string, params?: unknown[]) {
  const client = await pool.connect();
  try {
    return await client.query(text, params);
  } finally {
    client.release();
  }
}

export async function testConnection(): Promise<boolean> {
  try {
    const res = await query("SELECT version()");
    console.log(`[DB] Conectado: ${res.rows[0].version.split(",")[0]}`);
    return true;
  } catch (err: any) {
    console.error(`[DB] Falha conexão: ${err.message}`);
    return false;
  }
}

export async function close() {
  await pool.end();
}
