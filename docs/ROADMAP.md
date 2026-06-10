# ROADMAP — Dark World

## Fase 0 — Fundação [CONCLUÍDA]
- [x] Servidor dedicado Hetzner
- [x] Docker + Compose
- [x] PostgreSQL (porta 5433)
- [x] Redis (porta 6380)
- [x] Nakama (portas 7350/7351)
- [x] World Engine (estrutura)
- [x] Schema SQL inicial
- [x] Seeds iniciais
- [x] Backup automático
- [x] Documentação completa

## Fase 1 — MVP Técnico [EM BREVE]
- [ ] World Engine funcional (loop + eventos)
- [ ] Entity System (CRUD + componentes)
- [ ] Event Engine (fila + processamento)
- [ ] DeathModule
- [ ] AfterlifeModule
- [ ] TerritoryModule
- [ ] FactionModule
- [ ] DragonModule (placeholder)
- [ ] Teste com 2 jogadores

## Fase 2 — Godot Client [EM BREVE]
- [ ] Projeto Godot 4.x
- [ ] Conexão com Nakama
- [ ] Login/Criação de conta
- [ ] Cena de mundo (TileMap escuro)
- [ ] Movimentação básica
- [ ] Indicador de território
- [ ] Dragão placeholder visual

## Fase 3 — MVP Pai e Filho
- [ ] Dois jogadores conectam
- [ ] Ambos veem o mesmo mundo
- [ ] Um morre para o dragão
- [ ] Vai para Mundo dos Mortos
- [ ] Retorna por comando admin
- [ ] Tudo registrado em audit_logs

## Fase 4 — Polimento Inicial
- [ ] Admin Panel básico
- [ ] Monitoramento (Prometheus + Grafana)
- [ ] Anticheat básico (server-side validation)
- [ ] Logs estruturados

## Fase 5+ — Expansão
- [ ] Combate
- [ ] Economia
- [ ] Castelos
- [ ] Política avançada
- [ ] Múltiplos mundos
- [ ] Portais
- [ ] Dinastia
- [ ] Mobile
- [ ] Marketplace
