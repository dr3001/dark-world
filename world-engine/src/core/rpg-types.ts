export enum ItemType {
  WEAPON = "weapon",
  ARMOR = "armor",
  CONSUMABLE = "consumable",
  QUEST_ITEM = "quest_item",
  ACCESSORY = "accessory",
  MATERIAL = "material",
}

export enum Rarity {
  COMMON = "common",
  UNCOMMON = "uncommon",
  RARE = "rare",
  EPIC = "epic",
  LEGENDARY = "legendary",
  MYTHIC = "mythic",
}

export enum EquipSlot {
  WEAPON = "weapon",
  HELMET = "helmet",
  CHEST = "chest",
  GLOVES = "gloves",
  BOOTS = "boots",
  RING = "ring",
  AMULET = "amulet",
}

export enum QuestState {
  AVAILABLE = "available",
  ACTIVE = "active",
  COMPLETED = "completed",
  FAILED = "failed",
  TURNED_IN = "turned_in",
}

export enum TransactionType {
  LOOT = "loot",
  QUEST_REWARD = "quest_reward",
  PURCHASE = "purchase",
  SALE = "sale",
  TRADE = "trade",
  ADMIN_GRANT = "admin_grant",
  STRIPE_PURCHASE = "stripe_purchase",
}

export interface ICharacterStats {
  id: string;
  characterId: string;
  hp: number;
  maxHp: number;
  mana: number;
  maxMana: number;
  level: number;
  xp: number;
  zorium: number;
  strength: number;
  dexterity: number;
  intelligence: number;
  vitality: number;
  charisma: number;
  luck: number;
}

export interface IItem {
  id: string;
  name: string;
  itemType: ItemType;
  rarity: Rarity;
  slotType: EquipSlot | null;
  baseStats: Record<string, number>;
  description: string;
  stackable: boolean;
  maxStack: number;
  valueZorium: number;
}

export interface IInventorySlot {
  id: string;
  characterId: string;
  itemId: string;
  slotIndex: number;
  quantity: number;
}

export interface IEquipmentEntry {
  id: string;
  characterId: string;
  slotType: EquipSlot;
  itemId: string;
}

export interface IWallet {
  id: string;
  characterId: string;
  balance: number;
}

export interface ITransaction {
  id: string;
  fromWalletId: string | null;
  toWalletId: string | null;
  amount: number;
  txType: TransactionType;
  description: string;
  createdAt: Date;
}

export interface INPCProfile {
  id: string;
  entityId: string;
  role: string;
  personality: Record<string, unknown>;
  knowledge: Record<string, unknown>;
  aiProvider: string | null;
  aiConfig: Record<string, unknown>;
}

export interface INPCMemory {
  id: string;
  npcEntityId: string;
  characterId: string | null;
  memoryType: string;
  content: Record<string, unknown>;
  importance: number;
  createdAt: Date;
}

export interface IQuestData {
  id: string;
  name: string;
  description: string;
  questType: string;
  minLevel: number;
  requirements: Record<string, unknown>;
  rewards: Record<string, unknown>;
  chainNextId: string | null;
}

export interface IQuestProgress {
  id: string;
  characterId: string;
  questId: string;
  state: QuestState;
  progress: Record<string, unknown>;
  startedAt: Date | null;
  completedAt: Date | null;
}

export interface ISaveState {
  id: string;
  characterId: string;
  position: { x: number; y: number; z: number };
  statsSnapshot: Record<string, unknown>;
  inventorySnapshot: unknown[];
  equipmentSnapshot: Record<string, unknown>;
  questSnapshot: unknown[];
  savedAt: Date;
}

export const XP_PER_LEVEL = [
  0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 4000,
  5200, 6600, 8200, 10000, 12500, 15500, 19000, 23000, 28000, 34000,
];

export function xpForLevel(level: number): number {
  if (level <= 0) return 0;
  if (level <= XP_PER_LEVEL.length) return XP_PER_LEVEL[level - 1];
  return XP_PER_LEVEL[XP_PER_LEVEL.length - 1] + (level - XP_PER_LEVEL.length) * 5000;
}
