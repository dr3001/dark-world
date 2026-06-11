# Dark World — Landing Page Foundation

## APIs Disponiveis para Frontend Web

### Autenticacao
| Endpoint | Metodo | Descricao |
|----------|--------|-----------|
| /auth/register | POST | Criar conta (device_id) |
| /auth/restore | POST | Restaurar sessao (token) |

### Personagem
| Endpoint | Metodo | Descricao |
|----------|--------|-----------|
| /test/account | POST | Criar conta (display_name) |
| /test/character | POST | Criar personagem (account_id, character_name) |
| /characters/:id | GET | Dados do personagem |
| /characters/:id/stats | GET | Stats completos |
| /characters/:id/stats | PUT | Adicionar XP |

### Inventario e Equipamentos
| Endpoint | Metodo | Descricao |
|----------|--------|-----------|
| /characters/:id/inventory | GET | Listar inventario |
| /characters/:id/inventory | POST | Adicionar item |
| /characters/:id/equipment | GET | Listar equipamentos |
| /characters/:id/equipment/equip | POST | Equipar item |
| /characters/:id/equipment/unequip | POST | Desequipar item |

### Economia
| Endpoint | Metodo | Descricao |
|----------|--------|-----------|
| /characters/:id/wallet | GET | Saldo Zorium |
| /wallets/transfer | POST | Transferir Zorium |

### Quests
| Endpoint | Metodo | Descricao |
|----------|--------|-----------|
| /characters/:id/quests | GET | Listar quests |
| /characters/:id/quests/accept | POST | Aceitar quest |

### Mundo
| Endpoint | Metodo | Descricao |
|----------|--------|-----------|
| /worlds | GET | Listar mundos |
| /items | GET | Catalogo de itens |
| /dragons | GET | Dragoes ativos |

## Preparacao para Landing Page

### Paginas Planejadas
1. **Home** — apresentacao do jogo, download, trailer
2. **Cadastro/Login** — via /auth/register
3. **Perfil** — dados do personagem via /characters/:id
4. **Inventario Web** — visualizar itens via /characters/:id/inventory
5. **Wallet** — saldo e historico via /characters/:id/wallet
6. **Ranking** — leaderboard (futuro)

### Stack Recomendada
- Frontend: Next.js ou Astro
- Auth: Nakama tokens
- API: world-engine existente (porta 9000)
- Domain: dark.zorionlabs.net

### NAO implementado ainda
- Frontend web (apenas APIs prontas)
- Stripe integration (apenas tx_type preparado)
- Email de recuperacao de senha
