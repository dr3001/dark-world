# GITHUB EXPORT REPORT — Dark World

**Repo:** https://github.com/dr3001/dark-world
**Date:** 2026-06-10
**Branch:** main

## Published
- 219 files committed and pushed
- Complete project structure
- All source code (Godot + World Engine)
- All documentation (50+ reports)
- CI/CD pipelines (.github/workflows/)
- Docker configs, scripts, database migrations

## Project Structure
```
dark-world/
├── .github/workflows/    # CI/CD (3 pipelines)
├── godot-client/         # Godot 4 game client
│   ├── scenes/           # Login, World, Afterlife, Main
│   ├── scripts/          # GDScript files (8 scripts)
│   └── .godot/           # Godot project config
├── world-engine/         # Node.js backend
│   ├── src/              # TypeScript source
│   │   ├── core/         # Entity, Event, Module, WorldEngine
│   │   └── modules/      # Death, Afterlife, Dragon, Territory, Faction, Audit
│   └── tests/            # Test files
├── database/             # SQL migrations + seeds
├── docker/               # Nakama + Redis configs
├── scripts/              # 13 utility scripts
├── docs/                 # 80+ documentation files
├── docker-compose.yml    # Service orchestration
└── version.json          # Build tracking
```

## Excluded (.gitignore)
- node_modules/
- Build outputs (.exe, .app, .dmg, .tar.gz, .zip)
- Godot cache (.godot/imported/, .godot/editor/)
- Docker volumes
- Environment files (.env)
- Logs and temporary files
