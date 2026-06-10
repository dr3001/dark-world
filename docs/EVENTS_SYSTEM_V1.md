# EVENTS SYSTEM V1 — Dark World

## Eventos Implementados
- CHARACTER_DIED → DeathModule
- AFTERLIFE_ENTERED → AfterlifeModule
- AFTERLIFE_RETURNED → AfterlifeModule
- DRAGON_SPAWNED → DragonModule
- TERRITORY_CLAIMED → TerritoryModule
- ADMIN_EVENT_TRIGGERED → AuditModule

## Mecanismo
1. Evento criado na tabela events (status=created)
2. EventEngine.processNextEvents() lê eventos pendentes
3. Handler registrado processa o evento
4. Status muda para completed (ou failed)

## Pendente
- Fila via Redis (event_queue table existe mas não usada)
- Reprocessamento automático de falhas
- Prioridade de eventos
