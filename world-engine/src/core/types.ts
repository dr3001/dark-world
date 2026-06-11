// Dark World — Core Types
// Toda entidade, evento e componente do jogo deriva destas interfaces base.

// ============================================================
// ENTITY SYSTEM
// ============================================================

export type EntityId = string;
export type WorldId = string;
export type AccountId = string;

export enum EntityType {
  PLAYER = "player",
  CHARACTER = "character",
  DRAGON = "dragon",
  NPC = "npc",
  TERRITORY = "territory",
  KINGDOM = "kingdom",
  CASTLE = "castle",
  CITY = "city",
  FACTION = "faction",
  PORTAL = "portal",
  UNDEAD = "undead",
  ITEM = "item",
  WORLD = "world",
  EVENT = "event",
}

export interface IEntity {
  id: EntityId;
  type: EntityType;
  name: string;
  worldId: WorldId;
  ownerAccountId: AccountId | null;
  positionX: number;
  positionY: number;
  positionZ: number;
  state: Record<string, unknown>;
  metadata: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
}

export interface IEntityComponent {
  id: string;
  entityId: EntityId;
  componentType: string;
  data: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

// ============================================================
// EVENT ENGINE
// ============================================================

export enum EventType {
  PLAYER_CREATED = "PLAYER_CREATED",
  PLAYER_DELETED = "PLAYER_DELETED",
  CHARACTER_CREATED = "CHARACTER_CREATED",
  CHARACTER_DIED = "CHARACTER_DIED",
  CHARACTER_SENT_TO_AFTERLIFE = "CHARACTER_SENT_TO_AFTERLIFE",
  CHARACTER_RETURNED_FROM_AFTERLIFE = "CHARACTER_RETURNED_FROM_AFTERLIFE",
  TERRITORY_CLAIMED = "TERRITORY_CLAIMED",
  TERRITORY_CONTESTED = "TERRITORY_CONTESTED",
  TERRITORY_LOST = "TERRITORY_LOST",
  WAR_DECLARED = "WAR_DECLARED",
  WAR_ENDED = "WAR_ENDED",
  DRAGON_SPAWNED = "DRAGON_SPAWNED",
  DRAGON_ATTACKED_TERRITORY = "DRAGON_ATTACKED_TERRITORY",
  DRAGON_DEFEATED = "DRAGON_DEFEATED",
  UNDEAD_INVASION_STARTED = "UNDEAD_INVASION_STARTED",
  UNDEAD_INVASION_ENDED = "UNDEAD_INVASION_ENDED",
  PORTAL_OPENED = "PORTAL_OPENED",
  PORTAL_CLOSED = "PORTAL_CLOSED",
  AFTERLIFE_ENTERED = "AFTERLIFE_ENTERED",
  AFTERLIFE_RETURNED = "AFTERLIFE_RETURNED",
  ADMIN_EVENT_TRIGGERED = "ADMIN_EVENT_TRIGGERED",
  ITEM_ACQUIRED = "ITEM_ACQUIRED",
  ITEM_DROPPED = "ITEM_DROPPED",
  ITEM_EQUIPPED = "ITEM_EQUIPPED",
  ITEM_UNEQUIPPED = "ITEM_UNEQUIPPED",
  ZORIUM_EARNED = "ZORIUM_EARNED",
  ZORIUM_SPENT = "ZORIUM_SPENT",
  QUEST_ACCEPTED = "QUEST_ACCEPTED",
  QUEST_COMPLETED = "QUEST_COMPLETED",
  LEVEL_UP = "LEVEL_UP",
  STAT_CHANGED = "STAT_CHANGED",
  NPC_INTERACTION = "NPC_INTERACTION",
  GAME_SAVED = "GAME_SAVED",
}

export enum EventStatus {
  PENDING = "pending",
  PROCESSING = "processing",
  COMPLETED = "completed",
  FAILED = "failed",
  RETRYING = "retrying",
}

export interface IEvent {
  id: string;
  eventType: EventType;
  sourceEntityId: EntityId | null;
  targetEntityId: EntityId | null;
  worldId: WorldId | null;
  payload: Record<string, unknown>;
  status: EventStatus;
  createdAt: Date;
  processedAt: Date | null;
  createdBy: AccountId | null;
  errorMessage: string | null;
  retryCount: number;
}

// ============================================================
// WORLD ENGINE
// ============================================================

export interface IWorldEngineConfig {
  tickIntervalMs: number;
  dbHost: string;
  dbPort: number;
  dbUser: string;
  dbPassword: string;
  dbName: string;
  redisHost: string;
  redisPort: number;
  redisPassword: string;
  enginePort: number;
}

export interface IWorldEngineModule {
  name: string;
  enabled: boolean;
  initialize(): Promise<void>;
  onTick(): Promise<void>;
  shutdown(): Promise<void>;
}

// ============================================================
// GAME ENTITIES (interfaces específicas)
// ============================================================

export interface IPlayer {
  accountId: AccountId;
  displayName: string;
  characters: EntityId[];
  createdAt: Date;
}

export interface ICharacter {
  entityId: EntityId;
  playerAccountId: AccountId;
  name: string;
  factionId: EntityId | null;
  isAlive: boolean;
  deathCount: number;
  afterlifeWorldId: WorldId | null;
  lastDeathAt: Date | null;
}

export interface IDragon {
  entityId: EntityId;
  dragonType: string;
  isAlive: boolean;
  territoryId: EntityId | null;
  spawnWorldId: WorldId;
  lastSpawnedAt: Date | null;
}

export interface ITerritory {
  entityId: EntityId;
  territoryType: string;
  controllingFactionId: EntityId | null;
  contested: boolean;
  riskLevel: number;
}

export interface IKingdom {
  entityId: EntityId;
  rulerAccountId: AccountId | null;
  territories: EntityId[];
  factions: EntityId[];
}

export interface IFaction {
  entityId: EntityId;
  factionType: string;
  memberCount: number;
  alliedFactions: EntityId[];
  enemyFactions: EntityId[];
}

export interface IWar {
  id: string;
  attackerFactionId: EntityId;
  defenderFactionId: EntityId;
  startedAt: Date;
  endedAt: Date | null;
  status: "active" | "ended" | "truce";
}

export interface IDeathRecord {
  id: string;
  characterId: EntityId;
  killedByEntityId: EntityId | null;
  worldId: WorldId;
  deathLocation: { x: number; y: number; z: number };
  afterlifeWorldId: WorldId | null;
  diedAt: Date;
  returnedAt: Date | null;
}

export interface IAuditLog {
  id: string;
  eventType: EventType;
  entityId: EntityId | null;
  accountId: AccountId | null;
  action: string;
  details: Record<string, unknown>;
  createdAt: Date;
}
