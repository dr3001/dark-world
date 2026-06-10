export interface IWorldEngineModule {
  name: string;
  enabled: boolean;
  initialize(): Promise<void>;
  onTick(): Promise<void>;
  shutdown(): Promise<void>;
}

export abstract class WorldEngineModule implements IWorldEngineModule {
  abstract name: string;
  enabled = true;

  async initialize(): Promise<void> {}
  async onTick(): Promise<void> {}
  async shutdown(): Promise<void> {}
}
