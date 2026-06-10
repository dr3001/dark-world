# ROOT CAUSE ANALYSIS — DarkWorld.app "Damaged"

**Status:** REPROVADO (macOS bloqueia abertura)
**Classificacao:** **ASSINATURA** (ausencia total de code signature)

---

## Diagnostico Tecnico

### O que foi verificado no binario

| Item | Resultado |
|------|-----------|
| FAT universal binary | VALIDO (Magic: 0xcafebabe) |
| x86_64 slice | VALIDO (Mach-O EXECUTE, 45 load commands) |
| arm64 slice | VALIDO (Mach-O EXECUTE) |
| Info.plist CFBundleExecutable | VALIDO (DarkWorld) |
| Info.plist CFBundleIdentifier | VALIDO (com.darkworld.game) |
| Info.plist CFBundlePackageType | VALIDO (APPL) |
| PkgInfo | VALIDO (APPL????, 8 bytes) |
| .pck (MacOS/) | VALIDO (GDPC magic, 22KB) |
| .pck (Resources/) | VALIDO (GDPC magic, 22KB) |
| Min macOS version | 10.15 (compativel) |
| **CODE SIGNATURE** | **AUSENTE — ZERO ASSINATURA** |

### O binario NAO esta corrompido

O executavel e um Mach-O universal perfeitamente valido.
O bundle esta estruturalmente correto (Info.plist, PkgInfo, Resources, MacOS).
O .pck esta no local correto para o Godot runtime encontra-lo.

**O unico problema e a ausencia total de assinatura de codigo.**

---

## Por que "damaged"

No macOS 10.15+ (Catalina em diante), o Gatekeeper exige que TODO
executavel tenha pelo menos uma assinatura ad-hoc.

Uma assinatura ad-hoc NAO e uma assinatura de desenvolvedor Apple.
Ela e generada localmente pelo comando:

    codesign --force --deep --sign - DarkWorld.app

O "-" (hifen) significa "ad-hoc" — assine sem certificado.

Sem essa assinatura, o macOS classifica o app como "damaged"
(que na verdade significa "nao confio neste codigo, recuso executar").

---

## Por que nao conseguimos assinar

O build e feito em **Linux** (servidor Hetzner).
O comando `codesign` so existe no **macOS**.
Nao existe ferramenta equivalente no Linux.

O Godot, quando roda `--export-release macOS` EM UM MAC:
1. Compila os scripts (.gd -> .gdc)
2. Empacota os recursos (.pck)
3. Copia o template do macOS
4. Preenche Info.plist
5. **Executa codesign --force --deep --sign -**  <-- ESTE PASSO
6. Cria DMG com hdiutil

No Linux, os passos 5 e 6 sao IMPOSSIVEIS.

---

## O que o usuario PRECISA fazer no Mac

### Opcao 1: Comando unico (se tem Xcode CLT)
```bash
cd ~/Downloads
tar -xzf DarkWorld-Mac.tar.gz
xattr -cr DarkWorld.app
codesign --force --deep --sign - DarkWorld.app
open DarkWorld.app
```

### Opcao 2: Se codesign nao existe
```bash
xcode-select --install
# (aguardar instalar)
# depois execute a Opcao 1
```

### Opcao 3: Verificar se codesign funcionou
```bash
codesign -dv --verbose=4 DarkWorld.app 2>&1 | head -3
```
Deve mostrar:
```
Executable=/Users/.../DarkWorld.app/Contents/MacOS/DarkWorld
Identifier=com.darkworld.game
Format=app bundle with Mach-O universal (x86_64 arm64)
```

---

## Solucao definitiva (futura)

Mover o build macOS para um Mac ou GitHub Actions macOS runner.
Apenas assim e possivel:
1. Executar codesign
2. Criar DMG com hdiutil
3. Opcional: notarizar o app

---

## Veredito Final

| Pergunta | Resposta |
|----------|----------|
| App esta corrompido? | NAO |
| Bundle esta quebrado? | NAO |
| Binario e invalido? | NAO |
| Falta assinatura? | **SIM** (causa raiz) |
| Da pra assinar no Linux? | NAO |
| Se eu entregar pra outro usuario Mac, abrira? | **NAO** — ate que ele execute codesign |

## Classificacao: ASSINATURA
