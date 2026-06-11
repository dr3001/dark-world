import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class AICoachModule extends WorldEngineModule {
  name = "AICoachModule";
  override async initialize() { console.log("[AICoachModule] Initialized — transcription + coaching ready"); }

  async startTranscription(userId: string, characterId: string | null) {
    const r = await query("INSERT INTO ai_transcription_sessions (user_id, character_id, started_at, status) VALUES ($1,$2,NOW(),'active') RETURNING *", [userId, characterId]);
    return r.rows[0];
  }
  async endTranscription(sessionId: string, duration: number, tokens: number) {
    const cost = tokens * 0.0001;
    await query("UPDATE ai_transcription_sessions SET status='completed', duration_seconds=$1, used_tokens=$2, cost_estimated=$3, completed_at=NOW() WHERE id=$4", [duration, tokens, cost, sessionId]);
    await query("INSERT INTO ai_usage_meters (user_id, service, tokens_used, cost_estimated) SELECT user_id, 'transcription', $1, $2 FROM ai_transcription_sessions WHERE id=$3", [tokens, cost, sessionId]);
  }
  async startCoaching(userId: string, characterId: string | null, coachingType: string, context: Record<string, unknown> = {}) {
    const r = await query("INSERT INTO ai_coaching_sessions (user_id, character_id, coaching_type, context, started_at) VALUES ($1,$2,$3,$4,NOW()) RETURNING *", [userId, characterId, coachingType, JSON.stringify(context)]);
    return r.rows[0];
  }
  async getCoachingSession(sessionId: string) {
    return (await query("SELECT * FROM ai_coaching_sessions WHERE id=$1", [sessionId])).rows[0];
  }
}
