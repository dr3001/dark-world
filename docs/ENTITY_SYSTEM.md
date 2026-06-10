# ENTITY SYSTEM — Dark World

## Princípio

Tudo no jogo é uma entidade. Jogador, dragão, território, castelo, item, portal — tudo deriva da mesma estrutura base.

Isso permite que novos tipos de entidade sejam adicionados sem alterar o modelo de dados.

## Estrutura Base

```typescript
interface IEntity {
  id: string;           // UUID único
  type: EntityType;     // player | dragon | territory | ...
  name: string;         // Nome visível
  worldId: string;      // Mundo em que está
  ownerAccountId: string | null;  // Dono (se aplicável)
  positionX: number;
  positionY: number;
  positionZ: number;
  state: Record<string, unknown>;   // Estado atual (vivo, morto, etc.)
  metadata: Record<string, unknown>; // Dados extras (JSONB)
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;  // Soft delete
}
```

## Componentes

Comportamento é adicionado via componentes, não via herança:

```typescript
interface IEntityComponent {
  id: string;
  entityId: string;
  componentType: string;  // health | inventory | combat | ...
  data: Record<string, unknown>;  // JSONB
  createdAt: Date;
  updatedAt: Date;
}
```

Exemplo: Um dragão com vida e inventário:
- Entidade: `{ id: "d1", type: "dragon", name: "Vermithrax" }`
- Componente: `{ entityId: "d1", type: "health", data: { hp: 5000, maxHp: 5000 } }`
- Componente: `{ entityId: "d1", type: "combat", data: { damage: 200, range: 10 } }`

## Tipos de Entidade

| Tipo | Descrição | MVP |
|------|-----------|-----|
| player | Conta de jogador | Sim |
| character | Personagem jogável | Sim |
| dragon | Dragão raro | Sim |
| npc | Criatura/monstro | Sim |
| territory | Território/região | Sim |
| kingdom | Reino | Sim |
| castle | Castelo/fortaleza | Não |
| city | Cidade | Não |
| faction | Facção | Sim |
| portal | Portal entre mundos | Não |
| undead | Morto-vivo | Não |
| item | Item no mundo | Não |
| world | Mundo (vivos, mortos) | Sim |

## Tabela SQL

```sql
CREATE TABLE entities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type VARCHAR(50) NOT NULL,
  name VARCHAR(255) NOT NULL,
  world_id UUID REFERENCES worlds(id),
  owner_account_id UUID REFERENCES accounts(id),
  position_x DOUBLE PRECISION DEFAULT 0,
  position_y DOUBLE PRECISION DEFAULT 0,
  position_z DOUBLE PRECISION DEFAULT 0,
  state JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE entity_components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  component_type VARCHAR(100) NOT NULL,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Decisão de Design

Usamos **Entity-Component** em vez de herança de classes para:
1. Adicionar comportamento sem alterar schema
2. Permitir combinações imprevistas (dragão com componente política?)
3. Facilitar serialização para o banco
4. Permitir hot-reload de componentes no futuro
