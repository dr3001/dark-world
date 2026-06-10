# EVENT ENGINE — Dark World

## Princípio

Toda ação importante no jogo gera um evento. Eventos são a fonte da verdade. O estado do mundo é derivado da sequência de eventos processados.

Nada acontece no jogo sem gerar um evento.

## Fluxo

```
Ação → Criar Evento → Validar → Enfileirar → Processar → Auditoria
                                                      ↓
                                              Atualizar Estado
```

## Estrutura do Evento

```typescript
interface IEvent {
  id: string;
  eventType: EventType;
  sourceEntityId: string | null;  // Quem causou
  targetEntityId: string | null;  // Quem sofreu
  worldId: string | null;
  payload: Record<string, unknown>;  // JSONB: dados específicos
  status: EventStatus;           // pending | processing | completed | failed
  createdAt: Date;
  processedAt: Date | null;
  createdBy: string | null;      // account_id que disparou
  errorMessage: string | null;
  retryCount: number;
}
```

## Tipos de Evento (MVP)

| Evento | Gatilho | Efeito |
|--------|---------|--------|
| PLAYER_CREATED | Novo registro | Cria conta |
| CHARACTER_CREATED | Jogador cria char | Cria entidade character |
| CHARACTER_DIED | HP = 0 | Ativa DeathModule |
| CHARACTER_SENT_TO_AFTERLIFE | Morte confirmada | Move para mundo mortos |
| CHARACTER_RETURNED_FROM_AFTERLIFE | Timer/admin | Retorna ao mundo vivos |
| TERRITORY_CLAIMED | Facção conquista | Atualiza controle |
| TERRITORY_CONTESTED | Outra facção ataca | Inicia disputa |
| WAR_DECLARED | Facção declara guerra | Cria registro de guerra |
| WAR_ENDED | Condições atendidas | Encerra guerra |
| DRAGON_SPAWNED | Evento raro/admin | Cria dragão no mundo |
| DRAGON_ATTACKED_TERRITORY | Dragão ataca | Aplica dano ao território |
| ADMIN_EVENT_TRIGGERED | Painel admin | Evento manual |
| AFTERLIFE_ENTERED | Personagem morre | Registra entrada |
| AFTERLIFE_RETURNED | Retorno | Registra saída |

## Processamento

```typescript
async function processEvent(event: IEvent) {
  // 1. Validar (regras de negócio)
  await validateEvent(event);
  
  // 2. Executar módulo correspondente
  const handler = getEventHandler(event.eventType);
  await handler.process(event);
  
  // 3. Marcar como completado
  event.status = EventStatus.COMPLETED;
  event.processedAt = new Date();
  
  // 4. Auditar
  await auditLog(event);
}
```

## Fila (Redis)

Eventos são enfileirados em Redis para processamento assíncrono:
- Lista `event_queue:pending` para eventos novos
- Lista `event_queue:failed` para eventos que falharam
- Reprocessamento automático com retry (máx 3 tentativas)

## Tabela SQL

```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  source_entity_id UUID REFERENCES entities(id),
  target_entity_id UUID REFERENCES entities(id),
  world_id UUID REFERENCES worlds(id),
  payload JSONB DEFAULT '{}',
  status VARCHAR(20) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  created_by UUID REFERENCES accounts(id),
  error_message TEXT,
  retry_count INTEGER DEFAULT 0
);

CREATE TABLE event_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES events(id),
  priority INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Decisão de Design

Usamos Event Sourcing parcial:
- Eventos são append-only
- Estado atual é materializado a partir do último processamento
- Full event sourcing (replay) fica para Tier 2
