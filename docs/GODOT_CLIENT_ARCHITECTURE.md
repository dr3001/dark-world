# GODOT CLIENT ARCHITECTURE — Dark World

## Estrutura

```
godot-client/
├── project.godot              # Config do projeto
├── scenes/
│   ├── Main.tscn              # Cena principal (mundo 3D)
│   ├── Login.tscn             # Tela inicial
│   ├── World.tscn             # Mundo dos Vivos (Vale Cinzento)
│   └── Afterlife.tscn         # Mundo Congelado
├── scripts/
│   ├── NetworkClient.gd       # HTTP requests para API
│   ├── PlayerController.gd    # Movimentação WASD
│   ├── WorldState.gd          # Estado do mundo (cache)
│   └── EntitySpawner.gd       # Spawn de entidades visuais
├── assets/
│   └── placeholder/           # Placeholders temporários
└── docs/
    └── GODOT_IMPORT_COMPATIBILITY.md
```

## Fluxo do Cliente

1. **Login** → POST /test/account → account_id
2. **Criar Personagem** → POST /test/character → entity_id
3. **Entrar no Mundo** → GET /worlds/:id/entities → lista entidades
4. **Spawnar Entidades** → EntitySpawner cria meshes placeholder
5. **Mover** → PlayerController (WASD) — local apenas (MVP)
6. **Morrer** → POST /events/character-died → Engine processa
7. **Afterlife** → GET /characters/:id → life_state=afterlife → trocar cena
8. **Retornar** → POST /events/afterlife-returned → life_state=returned

## Server Authoritative
- Cliente NUNCA decide vida/morte/posição de outros
- Cliente envia intenção via POST
- Servidor valida, processa, registra
- Cliente lê estado via GET
