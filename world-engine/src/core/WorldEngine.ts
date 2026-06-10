import { EventEngine } from "./EventEngine.js";
import { IWorldEngineModule } from "./Module.js";
import { testConnection as dbTest } from "../db.js";
import { testConnection as redisTest } from "../redis.js";
import { config } from "../config.js";
import { audit } from "../logger.js";

export class WorldEngine {
  public eventEngine = new EventEngine();
  private modules = new Map<string, IWorldEngineModule>();
  private running = false;

  registerModule(module: IWorldEngineModule) {
    this.modules.set(module.name, module);
    console.log(`[WorldEngine] Módulo registrado: ${module.name} (enabled: ${module.enabled})`);
  }

  async start() {
    console.log("=".repeat(50));
    console.log("[WorldEngine] Iniciando Dark World Engine v0.2.0");
    console.log("=".repeat(50));

    // Test connections
    const dbOk = await dbTest();
    const redisOk = await redisTest();
    if (!dbOk) throw new Error("PostgreSQL indisponível");
    if (!redisOk) console.warn("[WorldEngine] Redis indisponível — continuando sem cache");

    // Init modules
    this.running = true;
    for (const [, mod] of this.modules) {
      if (mod.enabled) {
        console.log(`[WorldEngine] Inicializando ${mod.name}...`);
        await mod.initialize();
      }
    }

    console.log(`[WorldEngine] ${this.modules.size} módulos carregados`);
    console.log(`[WorldEngine] Tick interval: ${config.tickInterval}ms`);
    console.log("[WorldEngine] Pronto.");

    // Main loop
    this.loop();
  }

  private async loop() {
    while (this.running) {
      try {
        // Process events
        const processed = await this.eventEngine.processNextEvents(10);

        // Run module ticks
        for (const [, mod] of this.modules) {
          if (mod.enabled) {
            await mod.onTick();
          }
        }

        if (processed > 0) {
          console.log(`[WorldEngine] Tick: ${processed} eventos processados`);
        }
      } catch (err: any) {
        console.error(`[WorldEngine] Erro no loop: ${err.message}`);
      }

      await new Promise((r) => setTimeout(r, config.tickInterval));
    }
  }

  async stop() {
    console.log("[WorldEngine] Desligando...");
    this.running = false;
    for (const [, mod] of this.modules) {
      if (mod.enabled) await mod.shutdown();
    }
  }
}
