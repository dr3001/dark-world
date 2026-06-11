# Dark World — Combat Preparation

## Status: INTERFACES DEFINIDAS — IMPLEMENTACAO PENDENTE

## Sistemas Planejados

### CombatSystem
- Gerencia combate entre entidades
- Turno real-time (nao por turnos)
- Cooldown de ataque global
- Range de ataque (melee/ranged)

### DamageSystem
- Formula: `(baseDamage + strength + attack) - (vitality + defense) * 0.5`
- Critical: chance baseada em `luck` e `critical` do equipamento
- Multiplicador critico: 1.5x
- Dano minimo: 1
- Implementado em `CombatPrepModule.calculateDamage()`

### TargetSystem
- Deteccao de alvo por proximidade
- Raycast para line of sight (futuro)
- Foco automatico no alvo mais proximo
- Indicador visual de alvo (futuro)

### SkillSystem (stub)
- `ISkillDefinition`: id, name, manaCost, cooldown, baseDamage, scalingStat, scalingFactor
- Skills escalam com stats do personagem
- Cooldown individual por skill
- Mana como recurso limitante

### StatusEffectSystem (stub)
- `IStatusEffect`: id, name, effectType, duration, stacks, modifiers
- Efeitos: poison, bleed, stun, slow, buff, debuff
- Stacking configurable por efeito
- Duration-based com tick interval

## Modulo Existente
- `CombatPrepModule` em `modules/combat/CombatPrepModule.ts`
- Interfaces TypeScript completas
- `calculateDamage()` implementado
- Sem integracao com client ainda

## Proximos Passos (fase combate)
1. Ativar DragonAI no mundo
2. Conectar click esquerdo → ataque → calculateDamage()
3. HP do dragao funcional
4. Morte do dragao → quest completion → rewards
5. Feedback visual (flash, particulas)
6. Sons placeholder
