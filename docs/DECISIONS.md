# DECISIONS — Dark World

Registro de decisões arquiteturais e seus motivos.

## 2026-06-10

### 1. Docker para infraestrutura do jogo
**Decisão:** Todos os serviços do jogo rodam em Docker.
**Motivo:** Isolamento total do Zorion (produção). Sem conflito de dependências. Portabilidade.

### 2. PostgreSQL na porta 5433
**Decisão:** Docker PostgreSQL mapeado para 5433 no host.
**Motivo:** PostgreSQL nativo do Zorion ocupa 5432. Sem conflito.

### 3. Redis na porta 6380
**Decisão:** Docker Redis mapeado para 6380 no host.
**Motivo:** Redis nativo do Zorion ocupa 6379.

### 4. Nakama 3.x via Docker
**Decisão:** Nakama como servidor multiplayer.
**Motivo:** Solução madura, open-source, com realtime, contas, matchmaking. Evita reinventar servidor de rede.

### 5. Nakama config via YAML (não CLI)
**Decisão:** Usar `nakama-config.yml` em vez de flags CLI.
**Motivo:** Nakama 3.x usa flags diferentes do 2.x. YAML é mais legível e versionável.

### 6. TypeScript para World Engine
**Decisão:** Node.js + TypeScript.
**Motivo:** Mesmo ecossistema que Zorion. Tipagem forte. Fácil de manter. Bom para JSONB/eventos.

### 7. Entity-Component (não herança)
**Decisão:** Sistema de entidades com componentes modulares.
**Motivo:** Adicionar comportamento sem alterar schema. Combinações imprevistas possíveis.

### 8. Event Sourcing parcial
**Decisão:** Eventos como fonte da verdade, estado materializado.
**Motivo:** Auditoria completa. Possibilidade de replay. Expansão futura para CQRS.

### 9. Nginx existente (não Docker)
**Decisão:** Usar Nginx nativo do Zorion para proxy reverso.
**Motivo:** Já serve 80/443. Basta adicionar server blocks para o jogo.

### 10. UFW mantido como está
**Decisão:** Não expor portas 7350/7351 externamente ainda.
**Motivo:** MVP usa rede interna. Exposição será feita via Nginx proxy reverso quando necessário.
