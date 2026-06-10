# NAKAMA SETUP — Dark World

**Serviço:** darkworld-nakama (Docker)
**Porta HTTP:** 7350
**Porta gRPC/Console:** 7351
**Rede:** darkworld-net (interna)

---

## Configuração

| Parâmetro | Valor |
|-----------|-------|
| Imagem | heroiclabs/nakama:3.31.0 |
| Banco | darkworld_nakama (PostgreSQL compartilhado) |
| Console | porta 7351 |
| Config | /opt/darkworld/docker/nakama/nakama-config.yml |

## Conexão

```bash
# Health check
curl http://localhost:7350/

# Console Web
http://5.78.142.138:7351/
```

## Credenciais Console

Ver arquivo `/opt/darkworld/docker/nakama/nakama-config.yml` ou `.env`.

## Estrutura

```
docker/nakama/
├── nakama-config.yml    # Configuração YAML
├── data/                # Dados persistentes Nakama
└── modules/             # Módulos Lua/Go (futuro)
```

## Migrations

As migrations foram executadas automaticamente (16 migrations aplicadas).

## Função no Jogo

- Gerenciamento de contas de jogadores
- Autenticação
- Sessões multiplayer em tempo real
- Matchmaking
- RPCs para comunicação cliente-servidor
- Presença de jogadores

## Status

**Ativo e operacional.** Console acessível na porta 7351.
