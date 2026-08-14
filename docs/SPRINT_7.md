# Sprint 7 — Correções do primeiro playtest

## Objetivo
Aplicar somente os ajustes observados no playtest da Sprint 6, preservando as mecânicas já aprovadas.

## Alterações

### 1. Inimigos não funcionam mais como plataformas
- `enemy_base.gd` agora cria exceção de colisão física entre o `CharacterBody2D` do jogador e cada inimigo.
- Jogador e inimigo podem atravessar/ocupar o mesmo espaço físico sem que o jogador fique apoiado sobre o corpo do inimigo.
- Hurtboxes e hitboxes continuam funcionando normalmente; dano depende de ataque, não de contato físico.

### 2. Estagiário mais lento ao fugir
- Velocidade de fuga: **88 -> 72 px/s**.
- Velocidade do jogador permanece **95 px/s**.
- Aceleração de fuga: **700 -> 600 px/s²**.
- Resultado esperado: ele ainda tenta escapar, mas o Cavaleiro consegue alcançá-lo correndo.

### 3. Plataforma central alcançável com pulo normal
- Plataforma do Atirador: centro Y **112 -> 136**.
- Topo da plataforma: Y **128**.
- Piso jogável: topo Y **156**.
- Desnível: **28 px**, dentro do salto teórico atual (~31,5 px).
- Não deve ser necessário dash ou usar inimigos como degrau.

### 4. Agachar / abaixar
Registrado no backlog. Não implementado nesta sprint para preservar o escopo do laboratório atual.

## Regressão esperada
Permanecem sem alteração:
- movimento;
- salto;
- dash;
- ataque básico;
- HP/dano;
- IA e ataques principais dos três inimigos.

## Checklist de validação
1. Tentar saltar sobre Espadachim, Estagiário e Coordenador: o jogador não deve ficar apoiado neles.
2. Perseguir o Estagiário apenas correndo: deve ser possível reduzir a distância e alcançá-lo.
3. Subir na plataforma central apenas com um salto normal.
4. Confirmar que ataques do jogador e dos inimigos continuam registrando dano.
5. Confirmar que dash mantém o comportamento aprovado na Sprint 6.
