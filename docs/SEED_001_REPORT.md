# SEED 001 REPORT — Mission 2

**Data:** 2026-06-10
**Arquivo:** /opt/darkworld/database/seeds/002_mission2_seed.sql

---

## Dados Inseridos

### Mundos (3)
| Slug | Nome | Tipo |
|------|------|------|
| living_world | Mundo dos Vivos | living |
| frozen_afterlife | Mundo Congelado | frozen |
| shadow_realm | Reino das Sombras | shadow |

### Territórios (1)
| Nome | Mundo | Facção Controladora | Perigo |
|------|-------|---------------------|--------|
| Vale Cinzento | Mundo dos Vivos | Reino Central | 1 |

### Facções (2)
| Nome | Tipo | Mundo |
|------|------|-------|
| Reino Central | kingdom | Mundo dos Vivos |
| Legião Gelada | undead_horde | Mundo Congelado |

### Dragões (1)
| Nome | Tipo | Ameaça | Mundo | Vivo |
|------|------|--------|-------|------|
| Vorak, o Antigo | ancient | 10 | Mundo dos Vivos | Sim |

### Eventos Iniciais (2)
| Tipo | Status |
|------|--------|
| WORLD_CREATED | completed |
| DRAGON_SPAWNED | completed |

### Auditoria (2)
| Ação | Alvo |
|------|------|
| worlds_seeded | living_world |
| dragon_spawned | Vorak, o Antigo |

## Comando de Aplicação

```bash
cat /opt/darkworld/database/seeds/002_mission2_seed.sql | \
  docker exec -i darkworld-postgres psql -U darkworld_admin -d darkworld
```

## Validação

```sql
SELECT slug, name, world_type FROM worlds;
SELECT name, entity_type FROM entities;
SELECT dragon_name, threat_level FROM dragons;
```

## Conclusão

Seeds aplicados com sucesso. Dados iniciais completos: 3 mundos, 1 território, 2 facções, 1 dragão, 2 eventos iniciais, 2 registros de auditoria.
