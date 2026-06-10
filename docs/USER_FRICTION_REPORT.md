# USER FRICTION REPORT — Dark World v0.2.0

## Current User Journey (REPROVADO)

| Step | Action | Friction | Required |
|------|--------|----------|----------|
| 1 | Acessar dark.zorionlabs.net | Nenhum | Browser |
| 2 | Clicar Downloads | Nenhum | Click |
| 3 | Baixar .tar.gz | Nenhum | Click |
| 4 | Extrair .tar.gz | **ALTA** | Finder ou Terminal |
| 5 | Abrir Terminal | **CRITICA** | Terminal.app |
| 6 | Executar xattr -cr | **CRITICA** | Comando manual |
| 7 | Executar codesign | **CRITICA** | Comando manual + Xcode CLT |
| 8 | Abrir app | Nenhum | Click |
| 9 | Criar usuario | Baixo | Click no jogo |
| 10 | Entrar no mundo | Baixo | Click no jogo |

## Friction Points (bloqueiam usuario comum)

| # | Ponto | Severidade | Como resolver |
|---|-------|-----------|---------------|
| F1 | .tar.gz requer extracao manual | ALTA | Usar .dmg (monta automatico) |
| F2 | Terminal necessario | CRITICA | Eliminar comandos manuais |
| F3 | xattr -cr necessario | CRITICA | Assinar app ou usar DMG |
| F4 | codesign necessario | CRITICA | Assinar app ou usar DMG |
| F5 | Xcode CLT necessario | CRITICA | Nao depender de ferramentas dev |
| F6 | Botoes "CRIAR USUARIO TESTE" | MEDIA | Renomear para "Criar Conta" |

## Target User Journey (OBJETIVO)

| Step | Action | Friction |
|------|--------|----------|
| 1 | Acessar dark.zorionlabs.net | Nenhum |
| 2 | Clicar Download | Nenhum |
| 3 | Baixar .dmg | Nenhum |
| 4 | .dmg monta automatico | Nenhum |
| 5 | Arrastar app para Applications | Nenhum |
| 6 | Abrir app | Nenhum |
| 7 | Criar conta | Click no jogo |
| 8 | Jogar | Nenhum |

## Bloqueios Tecnicos

### Bloqueio 1: DMG no Linux
hdiutil e um comando macOS-only. Criar DMG no Linux requer
HFS+ filesystem tools que nao existem ou nao sao confiaveis.
Solucao: build em Mac ou GitHub Actions macOS runner.

### Bloqueio 2: Codesign no Linux
codesign e macOS-only. Apps macOS precisam de assinatura
ad-hoc minima. Sem codesign, macOS mostra "damaged".
Solucao: build em Mac.

### Bloqueio 3: Godot export no Linux
O export macOS do Godot falha com erro de bundle identifier
no ConfigFile parser. Mesmo se funcionasse, ainda precisaria
de codesign (macOS-only).
