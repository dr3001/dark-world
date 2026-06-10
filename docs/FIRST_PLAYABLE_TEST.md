# FIRST PLAYABLE TEST — Mission 4

## Como Testar

### 1. Abrir Godot no Mac
```bash
open ~/Projects/darkworld/godot-client/project.godot
```

### 2. Executar o Projeto (F5)
A tela inicial "DARK WORLD" aparece com botões:
- ENTRAR NO MUNDO
- CRIAR USUARIO TESTE
- SAIR

### 3. Criar Usuário Teste
Clica "CRIAR USUARIO TESTE" → API cria conta automaticamente.

### 4. Entrar no Mundo
Clica "ENTRAR NO MUNDO" → Cena World carrega:
- Terreno escuro visível
- Jogador (cilindro azul) aparece no centro
- Dragão (cubo vermelho) visível ao longe
- Território (plano verde) visível

### 5. Andar
WASD para mover o personagem.
Câmera em terceira pessoa, levemente elevada.

### 6. Morrer (Debug)
Pressiona K → Evento CHARACTER_DIED enviado ao servidor.
Servidor processa → Personagem vai para Mundo Congelado.
Cena muda automaticamente para Afterlife.

### 7. Retornar (Debug)
Na tela do Mundo Congelado, pressiona R.
Personagem retorna ao Vale Cinzento.

### 8. Ver Dragão
Aproximar-se do dragão (posição 200, 200).
Label "Vorak, o Antigo [AMEACA LETAL]" visível.

### 9. Ver Eventos
EventLog no canto superior esquerdo mostra eventos recentes.
