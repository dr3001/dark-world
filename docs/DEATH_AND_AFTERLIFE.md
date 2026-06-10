# DEATH AND AFTERLIFE — Dark World

## Fluxo de Morte
1. Personagem sofre dano fatal → evento CHARACTER_DIED
2. DeathModule processa: marca life_state=dead, registra em deaths
3. Cria evento AFTERLIFE_ENTERED
4. AfterlifeModule processa: move entidade para frozen_afterlife
5. life_state muda para afterlife

## Retorno
1. Admin ou timer cria evento AFTERLIFE_RETURNED
2. AfterlifeModule processa: move entidade de volta para living_world
3. life_state muda para returned
4. afterlife_records atualizado com returned_at

## Configuração
- AFTERLIFE_TEST_MINUTES=5 (para testes)
- No jogo real: 15 dias

## Perda de Bens (futuro)
- Parte saqueável, parte protegida, parte atravessa mundos
- Configurável por módulo
