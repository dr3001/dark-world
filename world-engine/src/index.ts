import { WorldEngine } from "./core/WorldEngine.js";
import { DeathModule } from "./modules/death/DeathModule.js";
import { AfterlifeModule } from "./modules/afterlife/AfterlifeModule.js";
import { DragonModule } from "./modules/dragon/DragonModule.js";
import { TerritoryModule } from "./modules/territory/TerritoryModule.js";
import { FactionModule } from "./modules/faction/FactionModule.js";
import { AuditModule } from "./modules/audit/AuditModule.js";
import { CharacterStatsModule } from "./modules/character/CharacterStatsModule.js";
import { ItemModule } from "./modules/item/ItemModule.js";
import { InventoryModule } from "./modules/inventory/InventoryModule.js";
import { EquipmentModule } from "./modules/equipment/EquipmentModule.js";
import { WalletModule } from "./modules/economy/WalletModule.js";
import { QuestModule } from "./modules/quest/QuestModule.js";
import { NPCModule } from "./modules/npc/NPCModule.js";
import { CombatPrepModule } from "./modules/combat/CombatPrepModule.js";
import { LootModule } from "./modules/loot/LootModule.js";
import { handleRequest } from "./api.js";
import { createServer } from "http";
import { config } from "./config.js";

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
  engine.registerModule(new CharacterStatsModule());
  engine.registerModule(new ItemModule());
  engine.registerModule(new InventoryModule());
  engine.registerModule(new EquipmentModule());
  engine.registerModule(new WalletModule());
  engine.registerModule(new QuestModule());
  engine.registerModule(new NPCModule());
  engine.registerModule(new CombatPrepModule());
  engine.registerModule(new LootModule());

  engine.eventEngine.registerHandler("CHARACTER_DIED", (e) => deathMod.handleDeath(e));
  engine.eventEngine.registerHandler("AFTERLIFE_ENTERED", (e) => afterlifeMod.handleAfterlifeEntered(e));
  engine.eventEngine.registerHandler("AFTERLIFE_RETURNED", (e) => afterlifeMod.handleAfterlifeReturned(e));
  engine.eventEngine.registerHandler("DRAGON_SPAWNED", (e) => dragonMod.handleDragonSpawned(e));
  engine.eventEngine.registerHandler("TERRITORY_CLAIMED", (e) => territoryMod.handleTerritoryClaimed(e));
  engine.eventEngine.registerHandler("ADMIN_EVENT_TRIGGERED", async (e) => {
    console.log("[Admin] Evento manual: " + JSON.stringify(e.payload));
    await engine.eventEngine.logAudit({
      actorType: "admin", actorId: e.created_by, action: "admin_event_triggered",
      targetType: e.event_type, payload: e.payload as Record<string, unknown>,
    });
  });

  const server = createServer(handleRequest);
  server.listen(config.port, () => console.log("[WorldEngine] API server na porta " + config.port));

  process.on("SIGTERM", async () => { await engine.stop(); server.close(); process.exit(0); });
  process.on("SIGINT", async () => { await engine.stop(); server.close(); process.exit(0); });

  await engine.start();
}

main().catch((err) => { console.error("[WorldEngine] Erro fatal:", err); process.exit(1); });
