# Dark World — Chat System
## Canais: global, local, clan, system, staff
## Mensagem contem: user_id, display_name, vip_level, role, message, channel, moderation_status
## Moderacao: ok, flagged, deleted
## Visual: ChatPanel no HUD (400x160, semi-transparente), badges VIP/role por cor
## API: POST /chat/send, GET /chat/recent, GET /chat/:channel
## Tabela: chat_messages
## Polling: client busca /chat/recent a cada 5s
## Cores: admin=vermelho, staff=azul, mod=verde, VIP=ouro/prata/bronze
