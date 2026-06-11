import { WorldEngineModule } from "../../core/Module.js";

export interface ICombatAction {
  attackerId: string;
  targetId: string;
  skillId?: string;
  damage?: number;
  timestamp: Date;
}

export interface IDamageResult {
  rawDamage: number;
  mitigated: number;
  finalDamage: number;
  critical: boolean;
  targetHpRemaining: number;
}

export interface IStatusEffect {
  id: string;
  name: string;
  effectType: string;
  duration: number;
  stacks: number;
  modifiers: Record<string, number>;
}

export interface ISkillDefinition {
  id: string;
  name: string;
  manaCost: number;
  cooldown: number;
  baseDamage: number;
  scalingStat: string;
  scalingFactor: number;
  statusEffects: string[];
}

export class CombatPrepModule extends WorldEngineModule {
  name = "CombatPrepModule";

  override async initialize() {
    console.log("[CombatPrepModule] Interfaces ready — combat implementation pending");
  }

  calculateDamage(attackerStats: Record<string, number>, defenderStats: Record<string, number>, baseDamage: number): IDamageResult {
    const atk = (attackerStats.strength || 5) + (attackerStats.attack || 0);
    const def = (defenderStats.vitality || 5) + (defenderStats.defense || 0);
    const raw = baseDamage + atk;
    const mitigated = Math.max(0, Math.floor(def * 0.5));
    const critical = Math.random() < (attackerStats.critical || 0.05);
    const mult = critical ? 1.5 : 1.0;
    const final_ = Math.max(1, Math.floor((raw - mitigated) * mult));
    const hpRemaining = Math.max(0, (defenderStats.hp || 100) - final_);
    return { rawDamage: raw, mitigated, finalDamage: final_, critical, targetHpRemaining: hpRemaining };
  }
}
