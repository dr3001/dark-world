import { query } from "../db.js";

export interface EntityRow {
  id: string;
  world_id: string;
  entity_type: string;
  name: string;
  owner_account_id: string | null;
  position_x: number;
  position_y: number;
  position_z: number;
  status: string;
  state: Record<string, unknown>;
  metadata: Record<string, unknown>;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
}

export class Entity {
  static async create(params: {
    worldId: string;
    entityType: string;
    name: string;
    ownerAccountId?: string;
    positionX?: number;
    positionY?: number;
    positionZ?: number;
    state?: Record<string, unknown>;
    metadata?: Record<string, unknown>;
  }): Promise<EntityRow> {
    const res = await query(
      `INSERT INTO entities (world_id, entity_type, name, owner_account_id, position_x, position_y, position_z, state, metadata)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
      [
        params.worldId, params.entityType, params.name,
        params.ownerAccountId || null,
        params.positionX || 0, params.positionY || 0, params.positionZ || 0,
        JSON.stringify(params.state || {}),
        JSON.stringify(params.metadata || {}),
      ]
    );
    return res.rows[0];
  }

  static async findById(id: string): Promise<EntityRow | null> {
    const res = await query("SELECT * FROM entities WHERE id = $1 AND deleted_at IS NULL", [id]);
    return res.rows[0] || null;
  }

  static async findByWorld(worldId: string, entityType?: string): Promise<EntityRow[]> {
    const res = entityType
      ? await query("SELECT * FROM entities WHERE world_id = $1 AND entity_type = $2 AND deleted_at IS NULL", [worldId, entityType])
      : await query("SELECT * FROM entities WHERE world_id = $1 AND deleted_at IS NULL", [worldId]);
    return res.rows;
  }

  static async updateState(id: string, state: Record<string, unknown>): Promise<void> {
    await query("UPDATE entities SET state = $1, updated_at = NOW() WHERE id = $2", [JSON.stringify(state), id]);
  }

  static async updatePosition(id: string, x: number, y: number, z: number): Promise<void> {
    await query("UPDATE entities SET position_x = $1, position_y = $2, position_z = $3, updated_at = NOW() WHERE id = $4", [x, y, z, id]);
  }

  static async updateWorld(id: string, worldId: string): Promise<void> {
    await query("UPDATE entities SET world_id = $1, updated_at = NOW() WHERE id = $2", [worldId, id]);
  }

  static async setStatus(id: string, status: string): Promise<void> {
    await query("UPDATE entities SET status = $1, updated_at = NOW() WHERE id = $2", [status, id]);
  }
}
