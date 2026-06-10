# SECURITY MODEL — Dark World

## Server Authoritative
- O servidor é a única fonte da verdade
- Cliente envia intenção, servidor valida, grava, responde
- Cliente NUNCA decide: ouro, item, morte, território, dano final, progressão crítica

## O que fica no cliente
- Renderização gráfica
- Input do jogador
- Predição local (para fluidez)
- Cache de assets

## O que fica no servidor
- Estado do mundo
- Validação de ações
- Economia e itens
- Progressão de personagem
- Lógica de combate
- Eventos do mundo

## O que NUNCA fica só no cliente
- Quantidade de ouro
- Dano causado
- Posição de outros jogadores (authoritative)
- Estado de morte/vida
- Controle de território

## Anticheat básico (atual)
- Server-side validation de todas as ações
- Rate limiting (Nakama)
- Auditoria completa (audit_logs)

## Anticheat futuro
- Detecção de anomalias (velocidade, dano, recursos)
- Easy Anti-Cheat / BattlEye
- Shadow banning

## Senhas e Segredos
- Todas as senhas em .env (nunca em código)
- .env com permissão 600
- .env nunca versionado (.gitignore)
- API keys armazenadas em auth.json

## Firewall
- UFW: apenas portas 22, 80, 443 expostas
- Nakama e World Engine via rede Docker interna
- Fail2ban ativo para SSH e Nginx
