# NAKAMA VALIDATION — Mission 2

**Data:** 2026-06-10

## Status
| Item | Valor |
|------|-------|
| Container | darkworld-nakama |
| Imagem | heroiclabs/nakama:3.31.0 |
| Porta HTTP | 7350 |
| Porta Console | 7351 |
| HTTP Status | 200 |
| Banco | darkworld_nakama (PostgreSQL) |
| Migrations | 16 aplicadas |

## Logs (últimas linhas)
```
{"level":"info","ts":"2026-06-10T20:15:23.588Z","caller":"server/runtime.go:713","msg":"Found runtime modules","count":0,"modules":[]}
{"level":"info","ts":"2026-06-10T20:15:23.588Z","caller":"server/leaderboard_scheduler.go:109","msg":"Leaderboard scheduler start"}
{"level":"info","ts":"2026-06-10T20:15:23.588Z","caller":"server/leaderboard_scheduler.go:304","msg":"Leaderboard scheduler update","end_active":"-1ns","end_active_count":0,"expiry":"-1ns","expiry_count":0}
{"level":"info","ts":"2026-06-10T20:15:23.589Z","caller":"server/api.go:156","msg":"Starting API server for gRPC requests","port":7349}
{"level":"info","ts":"2026-06-10T20:15:23.590Z","caller":"server/api.go:318","msg":"Starting API server gateway for HTTP requests","port":7350}
{"level":"info","ts":"2026-06-10T20:15:23.591Z","caller":"server/console.go:241","msg":"Starting Console server for gRPC requests","port":7348}
{"level":"info","ts":"2026-06-10T20:15:23.592Z","caller":"server/console.go:347","msg":"Starting Console server gateway for HTTP requests","port":7351}
{"level":"info","ts":"2026-06-10T20:15:23.626Z","caller":"main.go:243","msg":"Startup done"}
```

## Config
Arquivo: /opt/darkworld/docker/nakama/nakama-config.yml
Usa DSN: darkworld_admin@postgres:5432/darkworld_nakama

## Console
Acessível em: http://5.78.142.138:7351/
Usuário: admin

## Conclusão
Nakama operacional. HTTP retorna 200. Migrations aplicadas. Console acessível.
