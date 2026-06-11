import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";
import { KNOWN_UUIDS } from "../../config.js";

const SEASONS = ["spring", "summer", "autumn", "winter"];
const WEATHER_STATES = ["clear", "cloudy", "light_rain", "heavy_rain", "storm", "fog"];

export class WorldSimulationModule extends WorldEngineModule {
  name = "WorldSimulationModule";
  private tickCount = 0;

  override async initialize() {
    console.log("[WorldSimulationModule] Initialized — day/night + weather + seasons");
  }

  override async onTick() {
    this.tickCount++;
    if (this.tickCount % 30 === 0) {
      await this.advanceTime();
    }
    if (this.tickCount % 150 === 0) {
      await this.updateWeather();
    }
  }

  async advanceTime() {
    const wid = KNOWN_UUIDS.WORLD_LIVING;
    const t = (await query("SELECT * FROM world_time WHERE world_id = $1", [wid])).rows[0];
    if (!t) return;
    let { hour, day, month, year, season } = t;
    hour = (hour + 1) % 24;
    if (hour === 0) {
      day++;
      if (day > 30) { day = 1; month++; }
      if (month > 12) { month = 1; year++; }
      const newSeason = SEASONS[Math.floor((month - 1) / 3) % 4];
      if (newSeason !== season) {
        season = newSeason;
        console.log(`[WorldSim] Season changed to ${season}`);
      }
    }
    await query("UPDATE world_time SET hour=$1, day=$2, month=$3, year=$4, season=$5, updated_at=NOW() WHERE world_id=$6",
      [hour, day, month, year, season, wid]);
  }

  async updateWeather() {
    const wid = KNOWN_UUIDS.WORLD_LIVING;
    const t = (await query("SELECT season FROM world_time WHERE world_id = $1", [wid])).rows[0];
    const cfg = (await query("SELECT * FROM world_season_config WHERE season = $1", [t?.season || "summer"])).rows[0];
    if (!cfg) return;
    const rainChance = parseFloat(cfg.rain_chance);
    const fogChance = parseFloat(cfg.fog_chance);
    const tempMin = parseFloat(cfg.temp_min);
    const tempMax = parseFloat(cfg.temp_max);
    let state = "clear";
    const roll = Math.random();
    if (roll < rainChance * 0.3) state = "heavy_rain";
    else if (roll < rainChance) state = "light_rain";
    else if (roll < rainChance + fogChance) state = "fog";
    else if (roll < rainChance + fogChance + 0.2) state = "cloudy";
    const temp = tempMin + Math.random() * (tempMax - tempMin);
    const humidity = state.includes("rain") ? 70 + Math.random() * 25 : 30 + Math.random() * 40;
    const wind = 2 + Math.random() * 20;
    const visibility = state === "fog" ? 20 + Math.random() * 30 : state.includes("rain") ? 50 + Math.random() * 30 : 90 + Math.random() * 10;
    await query("UPDATE world_weather SET state=$1, temperature=$2, humidity=$3, wind_speed=$4, visibility=$5, updated_at=NOW() WHERE world_id=$6",
      [state, temp.toFixed(1), humidity.toFixed(1), wind.toFixed(1), visibility.toFixed(1), wid]);
  }

  async getState() {
    const wid = KNOWN_UUIDS.WORLD_LIVING;
    const time = (await query("SELECT * FROM world_time WHERE world_id = $1", [wid])).rows[0];
    const weather = (await query("SELECT * FROM world_weather WHERE world_id = $1", [wid])).rows[0];
    return { time, weather };
  }

  async forceWeather(state: string) {
    await query("UPDATE world_weather SET state=$1, updated_at=NOW() WHERE world_id=$2", [state, KNOWN_UUIDS.WORLD_LIVING]);
  }

  async forceTime(hour: number) {
    await query("UPDATE world_time SET hour=$1, updated_at=NOW() WHERE world_id=$2", [hour, KNOWN_UUIDS.WORLD_LIVING]);
  }
}
