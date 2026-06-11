# Dark World — NPC AI System
## NPCs: Ferreiro (blacksmith), Curandeira (healer), Guarda (guard), Mercador (merchant), Campones (villager), Guardiao (guardian)
## Cada NPC tem: systemPrompt, allowedTopics, fallback estatico
## AI Provider: env AI_PROVIDER, AI_ENDPOINT, AI_MODEL, AI_API_KEY
## Compativel com: OpenAI, DeepSeek (qualquer endpoint /chat/completions)
## Safety: max 3 frases, proibido inventar itens/loja/pagamento/comandos admin
## Tabelas: npc_profiles, npc_memory, npc_conversation_contexts
## API: POST /npcs/:role/chat
## Fallback: resposta estatica quando AI_API_KEY nao configurada
