# MISSION 6 — TRUTH MATRIX

| Pergunta | Resposta | Evidencia |
|----------|----------|-----------|
| Launcher existe? | NAO (em breve) | DMG script criado, requer Mac |
| Instalador existe? | SIM | build_mac_dmg.sh + export_presets.cfg |
| Conta real existe? | SIM | POST /auth/register → Nakama JWT |
| Login real existe? | SIM | POST /auth/restore → valida token |
| Personagem existe? | SIM | POST /test/character → alive |
| Mundo carrega? | SIM | GET /worlds/:id/entities → 6 entities |
| Dragao aparece? | SIM | GET /dragons → Vorak, o Antigo |
| Morte funciona? | SIM | POST /events/character-died → afterlife |
| Mundo Congelado funciona? | SIM | frozen_afterlife world |
| Retorno funciona? | SIM | POST /events/afterlife-returned → returned |
| Jogador consegue entrar? | SIM | Fluxo completo via API |
| Pai e filho conseguem jogar? | PARCIAL | Multiplayer Nakama pronto, falta 2o cliente |
