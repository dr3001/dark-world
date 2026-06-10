import { query } from "../db.js";

export interface EventRow {
  id: string;
  event_type: string;
  source_entity_id: string | null;
  target_entity_id: string | null;
  world_id: string | null;
  payload: Record<string, unknown>;
  status: string;
  created_by: string;
  created_at: Date;
  processed_at: Date | null;
  error: string | null;
}

export class GameEvent {
  static async create(params: {
    eventType: string;
    sourceEntityId?: string;
    targetEntityId?: string;
    worldId?: string;
    payload?: Record<string, unknown>;
    createdBy?: string;
  }): Promise<EventRow> {
    const res = await query(
      "INSERT INTO events (event_type, source_entity_id, target_entity_id, world_id, payload, created_by) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *",
      [
        params.eventType,
        params.sourceEntityId || null,
        params.targetEntityId || null,
        params.worldId || null,
        JSON.stringify(params.payload || {}),
        params.createdBy || "system",
      ]
    );
    await query("INSERT INTO event_queue (event_id, priority) VALUES ($1, 100)", [res.rows[0].id]);
    return res.rows[0];
  }

  static async findById(id: string): Promise<EventRow | null> {
    const res = await query("SELECT * FROM events WHERE id = $1", [id]);
    return res.rows[0] || null;
  }

  static async findPending(limit = 10): Promise<EventRow[]> {
    const res = await query(
      "SELECT e.* FROM events e INNER JOIN event_queue q ON e.id = q.event_id WHERE e.status = $1 ORDER BY q.priority ASC, e.created_at ASC LIMIT $2",
      ["created", limit]
    );
    return res.rows;
  }

  static async markProcessing(id: string): Promise<void> {
    await query("UPDATE events SET status = $1 WHERE id = $2", ["processing", id]);
  }

  static async markCompleted(id: string): Promise<void> {
    await query("UPDATE events SET status = $1, processed_at = NOW() WHERE id = $2", ["completed", id]);
    await query("DELETE FROM event_queue WHERE event_id = $1", [id]);
  }

  static async markFailed(id: string, errorMsg: string): Promise<void> {
    await query("UPDATE events SET status = $1, error = $2 WHERE id = $3", ["failed", errorMsg, id]);
    await query("DELETE FROM event_queue WHERE event_id = $1", [id]);
  }
}
