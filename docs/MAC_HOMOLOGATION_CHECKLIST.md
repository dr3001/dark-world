# MAC HOMOLOGATION CHECKLIST — Dark World v0.2.0

**Data:** 2026-06-10 22:32 UTC
**Testador:** Rogerio
**Maquina:** Mac (Intel ou Apple Silicon)
**Objetivo:** Provar que DarkWorld.app abre, mostra login, conecta ao servidor.

---

## PREPARACAO (antes de comecar)

### 1. Baixar o app
```
http://direct-download.zorionlabs.net/DarkWorld-Mac.tar.gz
```
- [ ] Arquivo baixado em `~/Downloads/DarkWorld-Mac.tar.gz`
- [ ] Tamanho: ~59MB (61,647,174 bytes)
- [ ] SHA256: `425e05b8b9967510b991223e429d5591991d5ee25ffde58e981087414899e3ed`

### 2. Verificar integridade (Terminal)
```bash
cd ~/Downloads
shasum -a 256 DarkWorld-Mac.tar.gz
```
- [ ] Hash confere com o acima? Se NAO: baixe novamente.

### 3. Extrair
```bash
cd ~/Downloads
tar -xzf DarkWorld-Mac.tar.gz
```
- [ ] Pasta `DarkWorld.app` criada em `~/Downloads/`
- [ ] Se falhar: `tar: Error opening archive` → download corrompido, baixe novamente.

---

## PASSO 1 — VERIFICACAO PRE-ABERTURA

Abra o Terminal e cole cada comando. Anote a saida.

### 1.1 Arquivo existe?
```bash
ls -la ~/Downloads/DarkWorld.app/Contents/MacOS/DarkWorld
```
- [ ] Deve mostrar `-rwxr-xr-x` e tamanho ~184MB
- [ ] Se "No such file": a extracao falhou.

### 1.2 Tipo do binario
```bash
file ~/Downloads/DarkWorld.app/Contents/MacOS/DarkWorld
```
- [ ] Deve mostrar: `Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64:Mach-O 64-bit executable arm64]`
- [ ] Se mostrar "directory" ou "data": arquivo errado.

### 1.3 Bundle identifier
```bash
defaults read ~/Downloads/DarkWorld.app/Contents/Info.plist CFBundleIdentifier
```
- [ ] Deve mostrar: `com.darkworld.game`
- [ ] Se vazio ou erro: Info.plist corrompido.

### 1.4 Verificar assinatura (vai falhar — normal)
```bash
codesign -dv --verbose=4 ~/Downloads/DarkWorld.app 2>&1
```
- [ ] Deve mostrar: `code object is not signed at all`
- [ ] ISSO E ESPERADO. O app nao tem assinatura Apple.

### 1.5 Verificar Gatekeeper (vai falhar — normal)
```bash
spctl -a -vv ~/Downloads/DarkWorld.app 2>&1
```
- [ ] Deve mostrar: `rejected` ou `no usable signature`
- [ ] ISSO E ESPERADO.

### 1.6 Verificar quarentena
```bash
xattr -l ~/Downloads/DarkWorld.app 2>&1
```
- [ ] Se mostrar `com.apple.quarantine`: o app foi baixado da internet.
- [ ] Se vazio: ok.

### 1.7 Listar conteudo do bundle
```bash
ls -laR ~/Downloads/DarkWorld.app/Contents/
```
- [ ] Deve conter: Info.plist, PkgInfo, MacOS/DarkWorld, MacOS/DarkWorld.pck, Resources/DarkWorld.pck, Resources/icon.icns
- [ ] Se faltar MacOS/DarkWorld: extracao falhou.

---

## PASSO 2 — ASSINAR E REMOVER QUARENTENA

```bash
cd ~/Downloads
xattr -cr DarkWorld.app
codesign --force --deep --sign - DarkWorld.app
```
- [ ] `xattr -cr`: sem saida = sucesso
- [ ] `codesign`: sem saida = sucesso
- [ ] Se `codesign: command not found`: instale Xcode Command Line Tools: `xcode-select --install`
- [ ] Se `codesign: no identity found`: execute `sudo codesign --force --deep --sign - DarkWorld.app`

### 2.1 Confirmar assinatura ad-hoc
```bash
codesign -dv --verbose=4 ~/Downloads/DarkWorld.app 2>&1 | head -5
```
- [ ] Deve mostrar: `Signature=adhoc` ou `TeamIdentifier=not set`

---

## PASSO 3 — ABRIR O APP (MOMENTO CRITICO)

### 3.1 Primeira tentativa
```bash
open ~/Downloads/DarkWorld.app
```
OU clique com botao direito no `DarkWorld.app` no Finder → **Abrir**

### 3.2 O que deve acontecer:
- [ ] O icone do app ** pula no Dock ** (bounce)
- [ ] Uma ** janela abre ** com fundo escuro
- [ ] Titulo da janela: "DARK WORLD"
- [ ] Subtitulo: "Prototype v0.2"
- [ ] Tres botoes visiveis: ENTRAR NO MUNDO, CRIAR USUARIO TESTE, SAIR
- [ ] Status: "Pronto para conectar."

### 3.3 Se NAO abrir — colete IMEDIATAMENTE:

```bash
# Copie e cole TUDO no Terminal. Envie a saida completa.
echo "=== Console logs do DarkWorld ==="
log show --predicate process == DarkWorld --last 5m 2>/dev/null | tail -30

echo "=== Crash reports ==="
ls -lt ~/Library/Logs/DiagnosticReports/ 2>/dev/null | head -5

echo "=== Gatekeeper log ==="
log show --predicate subsystem == com.apple.securityd --last 2m 2>/dev/null | grep -i dark | tail -10

echo "=== Tentativa manual pelo Terminal ==="
~/Downloads/DarkWorld.app/Contents/MacOS/DarkWorld 2>&1

echo "=== Verificacao final ==="
codesign -dv --verbose=4 ~/Downloads/DarkWorld.app 2>&1
spctl -a -vv ~/Downloads/DarkWorld.app 2>&1
file ~/Downloads/DarkWorld.app/Contents/MacOS/DarkWorld
```

### 3.4 Possiveis erros e solucoes:

| Mensagem | Significado | Acao |
|----------|-------------|------|
| "App is damaged and cant be opened" | Quarentena ativa | Execute Passo 2 novamente |
| "App cant be opened because developer cannot be verified" | Gatekeeper | Botao direito → Abrir → Confirmar |
| "App quit unexpectedly" | Crash | Envie o crash report (passo 3.3) |
| Nada acontece (sem bounce) | Bundle quebrado | Envie saida do passo 3.3 |
| Janela abre mas preta | Renderizacao | Problema Godot — relate |
| Janela abre mas sem botoes | Scene corrompida | Relate |

---

## PASSO 4 — TESTE DE LOGIN (se o app abriu)

### 4.1 Criar usuario
- [ ] Clique em **CRIAR USUARIO TESTE**
- [ ] Status deve mudar para: "Conta criada! Criando personagem..."
- [ ] Depois: "Personagem criado! Entrando..."
- [ ] O app deve ** mudar de tela ** para o mundo 3D

### 4.2 Se erro no login:
```bash
# Testar se o servidor esta online
curl -s http://5.78.142.138:9000/health
```
- [ ] Deve retornar `{"status":"ok",...}`
- [ ] Se nao retornar: servidor offline → reporte imediatamente

### 4.3 Entrar no mundo
- [ ] Apos criar usuario, clique em **ENTRAR NO MUNDO**
- [ ] Deve carregar cena 3D com terreno cinza
- [ ] HUD visivel: "Vale Cinzento | Vivo"
- [ ] Painel debug inferior: botoes Matar/Retornar
- [ ] WASD move o personagem
- [ ] Mouse move a camera

---

## PASSO 5 — COLETA DE EVIDENCIAS

Se o app abrir, tire screenshots de cada tela:
- [ ] Tela de login
- [ ] Apos criar usuario (status)
- [ ] Mundo carregado (cena 3D)
- [ ] Painel debug visivel

Salve em: `~/Desktop/DarkWorld-Evidence/`

---

## PASSO 6 — RELATORIO FINAL

Preencha:

```
App abriu? [ ] SIM  [ ] NAO
Se SIM:
  Janela visivel? [ ] SIM  [ ] NAO
  Titulo "DARK WORLD"? [ ] SIM  [ ] NAO
  Botoes funcionais? [ ] SIM  [ ] NAO
  Criou usuario? [ ] SIM  [ ] NAO
  Entrou no mundo? [ ] SIM  [ ] NAO
  WASD funciona? [ ] SIM  [ ] NAO
  
Se NAO:
  Mensagem de erro exata: _______________
  Em qual passo falhou? _______________
  Console log anexado? [ ] SIM  [ ] NAO
```

Envie este checklist preenchido + screenshots + logs para correcao.
