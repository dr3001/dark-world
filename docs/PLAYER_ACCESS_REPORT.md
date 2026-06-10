# PLAYER ACCESS REPORT — Mission 7

## URLs Oficiais

| Descricao | URL | Status |
|-----------|-----|--------|
| Portal principal | https://zorionlabs.net/dark/ | 200 FUNCIONA |
| Dark World Site | https://zorionlabs.net/darkworld/ | 200 FUNCIONA |
| Página de cadastro | https://zorionlabs.net/darkworld/ | 200 (via app) |
| Página de login | https://zorionlabs.net/darkworld/ | 200 (via app) |
| Downloads | https://zorionlabs.net/dark/downloads/ | 200 FUNCIONA |
| Status | https://zorionlabs.net/dark/status/ | 200 FUNCIONA |
| Documentação | https://zorionlabs.net/dark/docs/ | 200 FUNCIONA |
| Relatórios | https://zorionlabs.net/dark/reports/ | 200 FUNCIONA |
| Instalador Mac | https://zorionlabs.net/dark/downloads/DarkWorld-Mac-v0.2.0.zip | 200 FUNCIONA (59MB) |
| dark.zorionlabs.net | N/A | NXDOMAIN (DNS nao configurado) |

## Cadastro

O cadastro é feito DENTRO do aplicativo:
1. Abrir DarkWorld.app
2. Clicar em "CRIAR USUARIO TESTE"
3. O app conecta ao World Engine (5.78.142.138:9000)
4. Conta criada automaticamente via API /test/account
5. Personagem criado via /test/character
6. Mundo carregado automaticamente

## Login

- Método: Nakama JWT
- URL da API: http://5.78.142.138:9000 (interna ao app)
- Token: JWT gerado pelo Nakama
- Sessão: Persistida pelo app Godot
- Fluxo: Device ID → Nakama auth → JWT → World Engine

## Download

| Pergunta | Resposta |
|----------|----------|
| Existe instalador Mac real? | **SIM** — DarkWorld.app (59MB zip) |
| Existe DMG real? | NAO (Linux nao suporta hdiutil) |
| Existe APP real? | **SIM** — DarkWorld.app universal binary |
| Existe launcher real? | NAO (app é auto-contido) |

## Teste Final — Jornada do Jogador

1. **Qual URL ele acessa primeiro?**
   https://zorionlabs.net/dark/

2. **Onde cria conta?**
   Dentro do app DarkWorld.app → botao CRIAR USUARIO TESTE

3. **Onde faz login?**
   Automático via Nakama (device auth)

4. **Onde baixa o jogo?**
   https://zorionlabs.net/dark/downloads/DarkWorld-Mac-v0.2.0.zip

5. **Como instala?**
   Extrair zip → Arrastar DarkWorld.app para Applications → Abrir

6. **Como entra no Vale Cinzento?**
   Clicar ENTRAR NO MUNDO na tela de login

7. **Como testa morte?**
   Botao [DEBUG] Matar Personagem no painel inferior

8. **Como entra no Mundo Congelado?**
   Automatico apos morte (afterlife)

9. **Como retorna?**
   Botao [DEBUG] Retornar dos Mortos no painel inferior

## Verdict

**O projeto pode ser testado por um jogador comum?**
**SIM — com ressalvas.**

### O que funciona:
- Download do app (59MB zip)
- Instalação (extrair e abrir)
- Autenticação automática
- Criação de personagem
- Entrada no mundo 3D
- Visualização do dragão Vorak
- Sistema de morte/afterlife
- Retorno ao mundo

### O que falta:
- Assinatura de código (Gatekeeper bloqueia — requer Abrir com botão direito)
- Notarização Apple (requer Apple Developer Program)
- DMG nativo (requer Mac com hdiutil)
- dark.zorionlabs.net DNS (nao configurado no Cloudflare)
- Instalador .pkg (requer ferramentas Apple)
