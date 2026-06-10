# MISSION 3 — COMPLETE INVENTORY

**Data:** 2026-06-10 20:38 UTC

## Docker Compose Services
| Service | Image | Status | Ports |
|---------|-------|--------|-------|
| darkworld-postgres | postgres:16-alpine | Healthy | 5433→5432 |
| darkworld-redis | redis:7-alpine | Healthy | 6380→6379 |
| darkworld-nakama | heroiclabs/nakama:3.31.0 | Healthy | 7350,7351 |

## Database (17 tables)
| Table | Rows | Classification |
|-------|------|----------------|
| accounts_profile | 1 | FUNCTIONAL |
| worlds | 3 | FUNCTIONAL |
| entities | 5 | FUNCTIONAL |
| entity_components | 5 | FUNCTIONAL |
| events | 7 | FUNCTIONAL |
| event_queue | 0 | PLACEHOLDER |
| audit_logs | 4 | FUNCTIONAL |
| characters | 1 | FUNCTIONAL |
| territories | 1 | FUNCTIONAL |
| factions | 2 | FUNCTIONAL |
| kingdoms | 0 | PLACEHOLDER |
| wars | 0 | PLACEHOLDER |
| afterlife_records | 1 | FUNCTIONAL |
| dragons | 1 | FUNCTIONAL |
| system_jobs | 0 | PLACEHOLDER |
| admin_actions | 0 | PLACEHOLDER |
| deaths | 1 | FUNCTIONAL |

## Directories
18 directories, 40 docs, 9 scripts, 18 TS files, 3 test files.

## World Engine
18 source files, 1128 lines, zero type errors, 6 modules, 6 event handlers.
