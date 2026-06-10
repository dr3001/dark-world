# MAC CLIENT SETUP — Dark World

## Pré-requisitos

### 1. Godot 4.x
- Download: https://godotengine.org/download/macos/
- Versão: Godot 4.3+ (Standard, NOT .NET/C#)
- Instalar: Arrastar .app para Applications

### 2. Git (já instalado no Mac)
```bash
git --version
```

### 3. Clonar Projeto
```bash
mkdir -p ~/Projects/darkworld
cd ~/Projects/darkworld
git clone https://github.com/seu-usuario/darkworld.git .
# Ou copiar os arquivos do servidor:
# scp -r root@5.78.142.138:/opt/darkworld/godot-client/ ~/Projects/darkworld/
```

### 4. Abrir no Godot
1. Abrir Godot
2. Import → Selecionar pasta `godot-client/`
3. Ou: File → Open → Selecionar `project.godot`

### 5. Arquitetura Mac
Verificar antes de instalar:
```bash
uname -m
# arm64 = Apple Silicon (M1/M2/M3)
# x86_64 = Intel
```
Baixar a versão correta do Godot para sua arquitetura.

### 6. Conexão com Servidor
O servidor está em: `5.78.142.138:9000`
Testar conexão:
```bash
curl http://5.78.142.138:9000/health
```
