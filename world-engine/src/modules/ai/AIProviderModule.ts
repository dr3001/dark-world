import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";

const NPC_ROLES: Record<string, { systemPrompt: string; allowedTopics: string[] }> = {
  blacksmith: { systemPrompt: "Voce e o Ferreiro Thorin do Vale Cinzento. Responda apenas sobre armas, forja, upgrades, materiais e historia da vila ligada a forja. Seja direto e profissional.", allowedTopics: ["armas","forja","upgrades","materiais","historia"] },
  healer: { systemPrompt: "Voce e a Curandeira Lyra do Vale Cinzento. Responda apenas sobre cura, pocoes, ferimentos, Vorak e protecao do vale.", allowedTopics: ["cura","pocoes","ferimentos","vorak","protecao"] },
  guard: { systemPrompt: "Voce e o Guardiao do Vale Cinzento. Responda apenas sobre seguranca, missoes, perigos, clas e ordem publica.", allowedTopics: ["seguranca","missoes","perigos","clas","ordem"] },
  merchant: { systemPrompt: "Voce e o Mercador Ivan do Vale Cinzento. Responda apenas sobre loja, itens, Zorium, eventos e mercadorias.", allowedTopics: ["loja","itens","zorium","eventos","mercadorias"] },
  villager: { systemPrompt: "Voce e o Campones Finn do Vale Cinzento. Responda apenas sobre rumores, vida no vale e historia local.", allowedTopics: ["rumores","vida","vale","historia"] },
  guardian: { systemPrompt: "Voce e o Guardiao do Vale. Responda sobre a missao principal, lore do mundo, Vorak e progressao do jogador.", allowedTopics: ["missao","lore","vorak","progressao"] },
};

const SAFETY_RULES = "NUNCA: dar comandos admin, inventar loja real, prometer pagamento, inventar item inexistente, falar fora do seu papel. Responda em portugues, maximo 3 frases.";

export class AIProviderModule extends WorldEngineModule {
  name = "AIProviderModule";
  private provider: string = "";
  private endpoint: string = "";
  private model: string = "";
  private apiKey: string = "";

  override async initialize() {
    this.provider = process.env.AI_PROVIDER || "";
    this.endpoint = process.env.AI_ENDPOINT || "";
    this.model = process.env.AI_MODEL || "deepseek-chat";
    this.apiKey = process.env.AI_API_KEY || "";
    console.log(`[AIProviderModule] Provider: ${this.provider || "none (static fallback)"}`);
  }

  async chat(npcRole: string, characterId: string, userMessage: string): Promise<string> {
    const role = NPC_ROLES[npcRole] || NPC_ROLES.villager;
    const memories = (await query("SELECT content FROM npc_memory WHERE npc_entity_id = $1 ORDER BY importance DESC, created_at DESC LIMIT 5", [npcRole])).rows;
    const memoryContext = memories.map((m: any) => JSON.stringify(m.content)).join("; ");

    if (!this.apiKey || !this.endpoint) {
      return this.staticFallback(npcRole, userMessage);
    }

    try {
      const systemMsg = role.systemPrompt + " " + SAFETY_RULES + (memoryContext ? " Memorias: " + memoryContext : "");
      const res = await fetch(this.endpoint + "/chat/completions", {
        method: "POST",
        headers: { "Authorization": "Bearer " + this.apiKey, "Content-Type": "application/json" },
        body: JSON.stringify({ model: this.model, messages: [{ role: "system", content: systemMsg }, { role: "user", content: userMessage }], max_tokens: 150, temperature: 0.7 }),
      });
      const data = await res.json() as any;
      const reply = data?.choices?.[0]?.message?.content || this.staticFallback(npcRole, userMessage);
      await query("INSERT INTO npc_conversation_contexts (npc_entity_id, character_id, context) VALUES ($1,$2,$3) ON CONFLICT DO NOTHING", [npcRole, characterId, JSON.stringify({ user: userMessage, npc: reply })]);
      return reply;
    } catch { return this.staticFallback(npcRole, userMessage); }
  }

  private staticFallback(npcRole: string, _msg: string): string {
    const fallbacks: Record<string, string> = {
      blacksmith: "Posso forjar armas para aventureiros. Use [F] para forjar.",
      healer: "Vorak ameaca o Vale. Posso curar suas feridas. Use [C].",
      guard: "Mantenha-se atento aos perigos da regiao.",
      merchant: "Tenho mercadorias para viajantes.",
      villager: "A vida era mais tranquila antes de Vorak.",
      guardian: "O dragao Vorak voltou. Fale com a curandeira.",
    };
    return fallbacks[npcRole] || "...";
  }
}
