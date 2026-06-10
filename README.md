# Dark World

**Dark Fantasy Medieval Brutal MMO**

Official domain: https://dark.zorionlabs.net

## About

Dark World is a dark fantasy medieval brutal MMO featuring:
- Persistent world with living entities
- Dragon encounters (Vorak, o Antigo)
- Death and Afterlife system
- Territory and faction warfare
- 3 worlds: Mundo dos Vivos, Mundo Congelado, Reino das Sombras

## Tech Stack

- **Game Engine:** Godot 4.6.3
- **Backend:** Node.js World Engine + PostgreSQL + Redis
- **Auth:** Nakama 3.31.0
- **Infra:** Docker Compose, Nginx, Cloudflare
- **CI/CD:** GitHub Actions

## Project Structure

```
darkworld/
├── godot-client/       # Godot 4 game client
│   ├── scenes/         # .tscn scene files
│   ├── scripts/        # .gd GDScript files
│   └── assets/         # Game assets
├── world-engine/       # Node.js backend
│   └── src/            # TypeScript source
├── database/           # SQL migrations and seeds
├── docker/             # Docker configs (nakama, redis)
├── scripts/            # Utility scripts
├── docs/               # Documentation
├── admin-panel/        # Admin web panel
├── monitoring/         # Monitoring configs
├── .github/workflows/  # CI/CD pipelines
└── docker-compose.yml  # Service orchestration
```

## Quick Start

```bash
# Start all services
docker compose up -d

# Check status
curl http://localhost:9000/health

# Download client
open https://dark.zorionlabs.net/downloads
```

## Builds

| Platform | Download |
|----------|----------|
| Windows | DarkWorld-Installer.exe |
| macOS | DarkWorld-Mac.tar.gz |

See: https://dark.zorionlabs.net/downloads

## Version

Current: v0.2.0 (prototype)
See: version.json
