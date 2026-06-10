# ARCHITECTURE — Dark World

## Visão Geral

Dark World é um jogo multiplayer persistente dark fantasy. O mundo continua vivo mesmo sem jogadores online. Toda ação gera eventos. Tudo é auditável.

## Stack Tecnológica

```
┌──────────────────────────────────────────────┐
│                 CLIENTE                       │
│           Godot Engine 4.x                    │
│    (Windows / Linux / Mac / Mobile)           │
└──────────────┬───────────────────────────────┘
               │ WebSocket / gRPC
┌──────────────▼───────────────────────────────┐
│              NAKAMA (7350/7351)               │
│    Contas · Autenticação · Realtime · RPC     │
└──────────────┬───────────────────────────────┘
               │ HTTP / RPC
┌──────────────▼───────────────────────────────┐
│           WORLD ENGINE (9000)                 │
│   Entity System · Event Engine · Modules      │
└──────┬───────────────────┬───────────────────┘
       │                   │
┌──────▼──────┐    ┌───────▼──────┐
│ PostgreSQL  │    │    Redis      │
│  (5433)     │    │   (6380)      │
│  Estado     │    │  Cache/Filas  │
└─────────────┘    └──────────────┘
```

## Princípios

1. **Server Authoritative** — O servidor decide tudo
2. **Entity System** — Tudo é entidade com componentes
3. **Event Sourcing** — Toda ação gera evento auditado
4. **Modular** — Novas mecânicas como plugins
5. **Persistente** — Mundo continua sem jogadores
6. **Isolado** — Zero conflito com produção existente (Zorion)

## Decisões Chave

| Decisão | Motivo |
|---------|--------|
| Docker para jogo | Isolamento do Zorion |
| Portas offset (5433, 6380) | Sem conflito com serviços nativos |
| PostgreSQL (não MariaDB) | Melhor para JSONB e eventos |
| Nakama (não custom) | Servidor multiplayer maduro e testado |
| TypeScript no Engine | Tipagem forte, mesmo ecossistema |
| YAML config (Nakama 3.x) | Formato nativo do Nakama |
