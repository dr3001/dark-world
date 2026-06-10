// Seed Run — script para executar testes do World Engine
// Uso: npx tsx src/seed-run.ts

import { WorldEngine } from "./core/WorldEngine.js";
import { DeathModule } from "./modules/death/DeathModule.js";
import { AfterlifeModule } from "./modules/afterlife/AfterlifeModule.js";
import { DragonModule } from "./modules/dragon/DragonModule.js";
import { TerritoryModule } from "./modules/territory/TerritoryModule.js";
import { FactionModule } from "./modules/faction/FactionModule.js";
import { AuditModule } from "./modules/audit/AuditModule.js";
import { KNOWN_UUIDS } from "./config.js";
import { query } from "./db.js";

async function main() {
  const engine = new WorldEngine();

  const deathMod = new DeathModule();
  const afterlifeMod = new AfterlifeModule();
  const dragonMod = new DragonModule();
  const territoryMod = new TerritoryModule();
  const factionMod = new FactionModule();
  const auditMod = new AuditModule();

  engine.registerModule(deathMod);
  engine.registerModule(afterlifeMod);
  engine.registerModule(dragonMod);
  engine.registerModule(territoryMod);
  engine.registerModule(factionMod);
  engine.registerModule(auditMod);

  engine.eventEngine.registerHandler("CHARACTER_DIED", (e) => deathMod.handleDeath(e));
  engine.eventEngine.registerHandler("AFTERLIFE_ENTERED", (e) => afterlifeMod.handleAfterlifeEntered(e));
  engine.eventEngine.registerHandler("AFTERLIFE_RETURNED", (e) => afterlifeMod.handleAfterlifeReturned(e));
  engine.eventEngine.registerHandler("DRAGON_SPAWNED", (e) => dragonMod.handleDragonSpawned(e));
  engine.eventEngine.registerHandler("TERRITORY_CLAIMED", (e) => territoryMod.handleTerritoryClaimed(e));
  engine.eventEngine.registerHandler("ADMIN_EVENT_TRIGGERED", async (e) => {
    await engine.eventEngine.logAudit({
      actorType: "admin", actorId: e.created_by, action: "admin_event_triggered",
      targetType: e.event_type, payload: e.payload as Record<string, unknown>,
    });
  });

  console.log("\n========================================");
  console.log("  DARK WORLD — TEST RUN");
  console.log("========================================\n");

  // 1. Criar account_profile
  console.log("[TEST] Criando account_profile...");
  const accRes = await query(
    `INSERT INTO accounts_profile (id, nakama_user_id, display_name, email)
     VALUES ($1,$2,$3,$4) ON CONFLICT (id) DO UPDATE SET display_name = $3 RETURNING *`,
    ["d0000000-0000-0000-0000-000000000001", "nakama-test-001", "Heroi Teste", "heroi@darkworld.test"]
  );
  console.log(`  Account: ${accRes.rows[0].display_name} (${accRes.rows[0].id.slice(0,8)})`);

  // 2. Criar entity (player_character)
  console.log("[TEST] Criando entity player_character...");
  const entRes = await query(
    `INSERT INTO entities (id, world_id, entity_type, name, owner_account_id, position_x, position_y, status)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT (id) DO UPDATE SET name = $4 RETURNING *`,
    ["d0000000-0000-0000-0000-000000000002", KNOWN_UUIDS.WORLD_LIVING, "player_character", "Heroi Teste",
     "d0000000-0000-0000-0000-000000000001", 50, 50, "active"]
  );
  const testEntityId = entRes.rows[0].id;
  console.log(`  Entity: ${entRes.rows[0].name} (${testEntityId.slice(0,8)})`);

  // 3. Criar character
  console.log("[TEST] Criando character...");
  await query(
    `INSERT INTO characters (id, account_id, entity_id, character_name, character_role, life_state)
     VALUES ($1,$2,$3,$4,$5,$6)`,
    ["d0000000-0000-0000-0000-000000000003", "d0000000-0000-0000-0000-000000000001",
     testEntityId, "Heroi Teste", "wanderer", "alive"]
  );
  console.log(`  Character: Heroi Teste (alive)`);

  // 4. Criar evento CHARACTER_DIED
  console.log("[TEST] Criando evento CHARACTER_DIED...");
  const deathEvent = await engine.eventEngine.createEvent({
    eventType: "CHARACTER_DIED",
    targetEntityId: testEntityId,
    worldId: KNOWN_UUIDS.WORLD_LIVING,
    payload: { reason: "test_kill", killed_by: "dragon" },
  });
  console.log(`  Evento: ${deathEvent.id.slice(0,8)}`);

  // 5. Processar eventos
  console.log("[TEST] Processando eventos (CHARACTER_DIED → AFTERLIFE_ENTERED)...");
  const processed1 = await engine.eventEngine.processNextEvents(10);
  console.log(`  Processados: ${processed1} eventos`);

  // 6. Verificar estado
  const charCheck1 = await query("SELECT life_state FROM characters WHERE entity_id = $1", [testEntityId]);
  console.log(`  life_state: ${charCheck1.rows[0]?.life_state}`);

  const afterlifeRec = await query("SELECT * FROM afterlife_records WHERE character_id = (SELECT id FROM characters WHERE entity_id = $1) ORDER BY entered_at DESC LIMIT 1", [testEntityId]);
  console.log(`  Afterlife record: ${afterlifeRec.rows[0] ? "EXISTE" : "NÃO EXISTE"}`);

  // 7. Criar evento AFTERLIFE_RETURNED
  console.log("[TEST] Criando evento AFTERLIFE_RETURNED...");
  const returnEvent = await engine.eventEngine.createEvent({
    eventType: "AFTERLIFE_RETURNED",
    targetEntityId: testEntityId,
    worldId: KNOWN_UUIDS.WORLD_FROZEN,
  });
  console.log(`  Evento: ${returnEvent.id.slice(0,8)}`);

  // 8. Processar novamente
  console.log("[TEST] Processando eventos (AFTERLIFE_RETURNED)...");
  const processed2 = await engine.eventEngine.processNextEvents(10);
  console.log(`  Processados: ${processed2} eventos`);

  // 9. Verificar retorno
  const charCheck2 = await query("SELECT life_state FROM characters WHERE entity_id = $1", [testEntityId]);
  console.log(`  life_state: ${charCheck2.rows[0]?.life_state}`);

  // 10. Verificar dragão
  console.log("[TEST] Criando evento DRAGON_SPAWNED...");
  const dragonEvent = await engine.eventEngine.createEvent({
    eventType: "DRAGON_SPAWNED",
    sourceEntityId: KNOWN_UUIDS.DRAGON_VORAK,
    worldId: KNOWN_UUIDS.WORLD_LIVING,
    payload: { location: { x: 200, y: 200 } },
  });
  const processed3 = await engine.eventEngine.processNextEvents(10);
  console.log(`  Processados: ${processed3} eventos`);

  // 11. Audit logs
  const audits = await query("SELECT count(*) as total FROM audit_logs");
  console.log(`\n[RESULT] Audit logs: ${audits.rows[0].total} registros`);

  const events = await query("SELECT event_type, status, count(*) FROM events GROUP BY event_type, status ORDER BY event_type");
  console.log("[RESULT] Eventos:");
  for (const row of events.rows) {
    console.log(`  ${row.event_type}: ${row.status} (${row.count})`);
  }

  console.log("\n========================================");
  console.log("  TESTE CONCLUÍDO COM SUCESSO");
  console.log("========================================");

  process.exit(0);
}

main().catch((err) => {
  console.error("TESTE FALHOU:", err);
  process.exit(1);
});
