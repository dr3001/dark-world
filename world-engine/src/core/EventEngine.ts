import { GameEvent, EventRow } from "./Event.js";
import { query } from "../db.js";
import { audit } from "../logger.js";

export type EventHandler = (event: EventRow) => Promise<void>;

export class EventEngine {
  private handlers = new Map<string, EventHandler>();

  registerHandler(eventType: string, handler: EventHandler) {
    this.handlers.set(eventType, handler);
    console.log(`[EventEngine] Handler registrado: ${eventType}`);
  }

  async createEvent(params: {
    eventType: string;
    sourceEntityId?: string;
    targetEntityId?: string;
    worldId?: string;
    payload?: Record<string, unknown>;
    createdBy?: string;
  }): Promise<EventRow> {
    const event = await GameEvent.create(params);
    console.log(`[EventEngine] Evento criado: ${event.event_type} (${event.id.slice(0, 8)})`);
    return event;
  }

  async enqueueEvent(eventId: string, priority = 100): Promise<void> {
    await query(
      "INSERT INTO event_queue (event_id, priority) VALUES ($1, $2) ON CONFLICT DO NOTHING",
      [eventId, priority]
    );
  }

  async processNextEvents(limit = 10): Promise<number> {
    const events = await GameEvent.findPending(limit);
    let processed = 0;

    for (const event of events) {
      try {
        await GameEvent.markProcessing(event.id);

        const handler = this.handlers.get(event.event_type);
        if (handler) {
          await handler(event);
          await GameEvent.markCompleted(event.id);
        } else {
          console.log(`[EventEngine] Handler não encontrado: ${event.event_type}, ignorando.`);
          await GameEvent.markCompleted(event.id);
        }
        processed++;
      } catch (err: any) {
        console.error(`[EventEngine] Erro processando ${event.event_type}: ${err.message}`);
        await GameEvent.markFailed(event.id, err.message);
      }
    }
    return processed;
  }

  async logAudit(params: {
    actorType: string;
    actorId?: string;
    action: string;
    targetType?: string;
    targetId?: string;
    payload?: Record<string, unknown>;
  }): Promise<void> {
    await query(
      `INSERT INTO audit_logs (actor_type, actor_id, action, target_type, target_id, payload)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [
        params.actorType,
        params.actorId || null,
        params.action,
        params.targetType || null,
        params.targetId || null,
        JSON.stringify(params.payload || {}),
      ]
    );
    audit(params.action, params.payload || {});
  }
}
