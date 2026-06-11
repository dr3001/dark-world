// Dark World SDK v1.0.0
// JavaScript client for the Dark World Public API

class DarkWorldSDK {
  constructor(baseURL = "https://dark.zorionlabs.net/dw-api") {
    this.baseURL = baseURL;
  }

  async _request(path, options = {}) {
    const url = this.baseURL + path;
    const res = await fetch(url, {
      headers: { "Content-Type": "application/json", ...options.headers },
      ...options
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json();
  }

  // World
  async getHealth() { return this._request("/health"); }
  async getWorldState() { return this._request("/world/state"); }

  // Classes
  async getClasses() { return this._request("/classes"); }
  async getClassById(id) { return this._request(`/classes/${id}`); }

  // Servers
  async getServers() { return this._request("/servers"); }

  // Multiplayer
  async getOnlinePlayers() { return this._request("/players/online"); }

  // Rankings
  async getGlobalRankings() { return this._request("/rankings/global"); }

  // Events
  async getEventCalendar() { return this._request("/events/calendar"); }

  // Territories
  async getTerritoryMap() { return this._request("/territories/map"); }

  // Public API v1
  async getPublicHealth() { return this._request("/api/public/v1/health"); }
  async getPublicWorldState() { return this._request("/api/public/v1/world/state"); }
  async getPublicCharacterProfile(characterId) { return this._request(`/api/public/v1/characters/${characterId}/profile`); }
  async getPublicRankings() { return this._request("/api/public/v1/rankings/global"); }

  // VIP
  async getVIPLevels() { return this._request("/vip/levels"); }

  // Store
  async getStoreProducts() { return this._request("/store/products"); }

  // Lore
  async getLoreCharacter(characterId) { return this._request(`/lore/character/${characterId}`); }
  async getLoreClan(clanId) { return this._request(`/lore/clan/${clanId}`); }
  async getLoreNPC(name) { return this._request(`/lore/npc/${encodeURIComponent(name)}`); }
  async getWorldChronicles() { return this._request("/lore/chronicles"); }

  // Forum
  async getForumCategories() { return this._request("/forum/categories"); }
  async getForumThreads() { return this._request("/forum/threads"); }
  async createForumThread(userId, categoryId, title, content) {
    return this._request("/forum/threads", {
      method: "POST",
      body: JSON.stringify({ user_id: userId, category_id: categoryId, title, content })
    });
  }
  async createForumPost(threadId, userId, content) {
    return this._request("/forum/posts", {
      method: "POST",
      body: JSON.stringify({ thread_id: threadId, user_id: userId, content })
    });
  }

  // Tickets
  async createTicket(userId, title, category, message) {
    return this._request("/tickets", {
      method: "POST",
      body: JSON.stringify({ user_id: userId, title, category, message })
    });
  }

  // Launcher
  async getLauncherStatus() { return this._request("/api/launcher/status"); }

  // Violations
  async getViolations() { return this._request("/violations"); }
}

if (typeof module !== "undefined") module.exports = DarkWorldSDK;
