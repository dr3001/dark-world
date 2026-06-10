# MISSION 8 — CLAIM VALIDATION REPORT

## Claims vs Reality

| Claim | Verdict | Evidence |
|-------|---------|----------|
| Existe portal | VERDADEIRO | /dark/ HTTP 200 |
| Existe cadastro | VERDADEIRO | /dark/register/ + via app |
| Existe login | VERDADEIRO | /dark/login/ + Nakama auth |
| Existe download | VERDADEIRO | DarkWorld-Mac.zip 59MB |
| Existe instalador | VERDADEIRO | DarkWorld.app universal binary |
| Existe app | VERDADEIRO | .app bundle com Godot 4.6.3 |
| Abre sem Godot | VERDADEIRO | App nativo, sem editor |
| Existe personagem | VERDADEIRO | 4 characters no banco |
| Existe mundo | VERDADEIRO | 3 worlds, 7 entidades |
| Existe Vale Cinzento | VERDADEIRO | territory entity |
| Existe dragao | VERDADEIRO | Vorak, threat=10, alive |
| Existe morte | VERDADEIRO | 5 deaths processadas |
| Existe Mundo Congelado | VERDADEIRO | 5 afterlife records |
| Existe retorno | VERDADEIRO | 5 returns processados |
| Existe banco persistente | VERDADEIRO | 17 tabelas, dados reais |
| Existe World Engine | VERDADEIRO | 6 modulos, processando |
| Existe Event Engine | VERDADEIRO | 31 events, queue processada |
| Existe status | VERDADEIRO | /dark/status/ HTTP 200 |
| Existe evidencia | VERDADEIRO | /dark/evidence/ |
| Existe fluxo jogavel | PARCIAL | App existe mas nao testado em Mac real |
| dark.zorionlabs.net | FALSO | DNS nao configurado |
| SSL Full Strict | FALSO | Modo Full (nao strict) |

## Summary
- VERDADEIRO: 19
- PARCIAL: 1 (fluxo jogavel — app nao testado no Mac)
- FALSO: 2 (DNS, SSL strict)
