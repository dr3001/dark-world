# MISSION 4 — PLAN

**Objetivo:** Primeira existência jogável no Mac via Godot 4.x

## Fases

| Fase | Descrição | Status |
|------|-----------|--------|
| 1 | API REST no World Engine (10 endpoints) | ✅ |
| 2 | Projeto Godot (project.godot, scenes, scripts) | ✅ |
| 3 | Documentação (MAC setup, arquitetura, API report) | ✅ |
| 4 | Teste API endpoints (fluxo completo) | ✅ |
| 5 | Relatórios finais | ✅ |

## Endpoints Criados

GET /health
GET /worlds
GET /worlds/:id/entities
POST /test/account
POST /test/character
GET /characters/:id
POST /events/character-died
POST /events/afterlife-returned
GET /events/recent
GET /dragons

## Cliente Godot

- project.godot configurado (WASD + teclas debug K/R)
- 4 scenes: Main, Login, World, Afterlife
- 6 scripts: NetworkClient, PlayerController, WorldState, EntitySpawner, EventClient, AuthClient
