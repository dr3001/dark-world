# WORLD ENGINE ARCHITECTURE — Dark World

## Visão Geral

O World Engine é o coração do jogo. Ele roda continuamente, processa eventos, atualiza o estado do mundo, e gerencia todas as entidades do jogo.

NÃO é o servidor de rede (Nakama).
NÃO é o banco de dados (PostgreSQL).
NÃO é o cache (Redis).

É o MOTOR que mantém o mundo vivo.

## Arquitetura

```
World Engine
├── Core
│   ├── Engine Loop (tick-based)
│   ├── Database Interface (PostgreSQL)
│   ├── Cache Interface (Redis)
│   └── Logger / Auditor
│
├── Entity System
│   ├── Entity Manager (CRUD genérico)
│   ├── Component Manager (add/remove comportamento)
│   └── Entity Registry (tipos registrados)
│
├── Event Engine
│   ├── Event Queue (Redis-backed)
│   ├── Event Processor (consome fila)
│   ├── Event Validator (regras de negócio)
│   └── Event Auditor (tudo registrado)
│
└── Module System
    ├── DeathModule
    ├── AfterlifeModule
    ├── TerritoryModule
    ├── FactionModule
    ├── DragonModule
    └── WorldEventModule
```

## Engine Loop

```typescript
async function engineLoop() {
  while (running) {
    // 1. Processar eventos pendentes
    await processEvents();
    
    // 2. Executar tick de cada módulo ativo
    for (const module of activeModules) {
      await module.onTick();
    }
    
    // 3. Aguardar próximo intervalo
    await sleep(tickIntervalMs);
  }
}
```

## Comunicação

```
Godot Client → Nakama (realtime) → RPC → World Engine
World Engine → PostgreSQL (estado persistente)
World Engine → Redis (cache, filas)
Admin Panel → World Engine API (porta 9000)
```

## Módulos (MVP)

| Módulo | Função | Status MVP |
|--------|--------|------------|
| DeathModule | Gerencia morte de personagens | Implementado |
| AfterlifeModule | Mundo dos mortos, retorno | Implementado |
| TerritoryModule | Controle territorial básico | Implementado |
| FactionModule | Facções e alianças | Implementado |
| DragonModule | Spawn e ataque de dragão | Placeholder |
| WorldEventModule | Eventos globais | Placeholder |

## Stack Técnica

- **Runtime:** Node.js + TypeScript
- **Banco:** PostgreSQL 16 (via pg library)
- **Cache:** Redis 7 (via ioredis)
- **Container:** Docker (Dockerfile)
- **API:** HTTP simples na porta 9000

## Expansão Futura

Novos módulos podem ser adicionados implementando a interface `IWorldEngineModule`:
```typescript
interface IWorldEngineModule {
  name: string;
  enabled: boolean;
  initialize(): Promise<void>;
  onTick(): Promise<void>;
  shutdown(): Promise<void>;
}
```
