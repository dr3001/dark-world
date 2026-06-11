import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

export class RankingModule extends WorldEngineModule {
  name = "RankingModule";
  override async initialize() { console.log("[RankingModule] Initialized"); }

  async getGlobal(rankingType: string = "xp", limit: number = 50) {
    return (await query("SELECT re.*, ap.display_name FROM ranking_entries re JOIN accounts_profile ap ON re.user_id = ap.id WHERE re.ranking_type = $1 ORDER BY re.score DESC LIMIT $2", [rankingType, limit])).rows;
  }
  async getSeason(seasonId: string, limit: number = 50) {
    return (await query("SELECT re.*, ap.display_name FROM ranking_entries re JOIN accounts_profile ap ON re.user_id = ap.id WHERE re.season_id = $1 ORDER BY re.score DESC LIMIT $2", [seasonId, limit])).rows;
  }
  async updateScore(userId: string, characterId: string | null, rankingType: string, score: number, seasonId?: string) {
    await query("INSERT INTO ranking_entries (user_id, character_id, ranking_type, score, season_id) VALUES ($1,$2,$3,$4,$5) ON CONFLICT DO NOTHING", [userId, characterId, rankingType, score, seasonId || null]);
  }
  async getSeasons() { return (await query("SELECT * FROM ranking_seasons ORDER BY starts_at DESC")).rows; }
}
