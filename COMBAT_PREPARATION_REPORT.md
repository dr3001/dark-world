# Dark World — Combat Preparation Report

## Status: ARQUITETURA PRONTA — IMPLEMENTACAO PENDENTE

## CombatSystem.gd (Client)
### Combat States
| Estado | Descricao |
|--------|-----------|
| IDLE | Sem alvo, sem acao |
| TARGETING | Alvo selecionado |
| ATTACKING | Executando ataque |
| COOLDOWN | Aguardando cooldown |
| DEFENDING | Em defesa (futuro) |

### Weapon System
- `set_weapon()` — carrega stats da arma equipada
- `base_damage` — calculado de weapon base_stats.attack
- `attack_range` — 4.0 base + weapon bonus
- `cooldown_timer` — 0.5 base - weapon speed bonus

### Damage Calculation
- Formula: `(strength + base_damage) - (vitality + defense) * 0.5`
- Critical: `luck * 0.02 + equipment_critical`
- Multiplicador critico: 1.5x
- Dano minimo: 1

### Target Lock
- Alvo mais proximo detectado automaticamente
- `set_target()` muda estado para TARGETING

## CombatPrepModule.ts (Server)
- `calculateDamage()` — formula espelhada no server
- Interfaces: ICombatAction, IDamageResult, IStatusEffect, ISkillDefinition

## Proximos Passos
1. Ativar DragonAI.gd no mundo
2. Conectar click esquerdo → CombatSystem.start_attack()
3. Enviar dano ao server, atualizar HP do dragao
4. Feedback visual (flash, particulas)
5. Morte do dragao → quest completion → loot
