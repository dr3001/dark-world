import { WorldEngineModule } from "../../core/Module.js";

export class FactionModule extends WorldEngineModule {
  name = "FactionModule";

  override async initialize() {
    console.log("[FactionModule] Pronto para gerenciar facções");
  }
}
