# Sprint 2 — Primeiro Inimigo Real

## Objetivo
Colocar o Mercenario Espadachim no laboratorio como primeira IA completa sem fechar nenhum valor de feeling antes do playtest.

## Implementado por DEV
- classe base reutilizavel `enemy_base.gd`
- vida, dano, morte, gravidade e feedback de hit reutilizaveis
- Mercenario Espadachim com 30 HP
- maquina de estados:
  - IDLE
  - ALERTA
  - PERSEGUIR
  - PREPARAR
  - ATAQUE
  - RECUPERAR
  - HIT
  - MORTO
- deteccao por distancia
- perseguição horizontal
- telegraph de 0,25 s
- golpe rapido com pequeno avanço
- dano provisório de 20 HP
- recuperacao provisoria de 0,40 s
- interrupcao por golpe do jogador
- knockback leve ao ser atingido
- label de debug mostrando o estado atual
- HP do inimigo visivel durante o laboratorio

## Valores atuais — TODOS PROVISORIOS
- deteccao: 190 px
- velocidade de perseguicao: 72 px/s
- alcance de ataque: 31 px
- alerta: 0,24 s
- preparacao: 0,25 s
- ataque ativo: 0,10 s
- recuperacao: 0,40 s
- dano: 20
- vida: 30
- hit stun: 0,11 s

Nenhum desses valores deve ser tratado como balanceamento final.

## Trabalho de DG
Criada a referencia tecnica `scenes/art/swordsman_silhouette_reference.tscn`.

Diretrizes atuais:
- 48 px de corpo
- espada curta como leitura principal
- ombreira assimetrica
- pequeno cilindro/tanque steampunk
- cracha corporativo discreto
- silhueta agressiva
- humor contextual, nunca pastelão

## Disposicao atual no laboratorio
- Cavaleiro: x 48
- Dummy: x 250
- Espadachim: x 390

Assim o jogador pode testar primeiro o ataque no dummy e depois encontrar o primeiro inimigo real.

## Checkpoint futuro no PC
Contra um unico Espadachim, registrar:
1. ele percebe o jogador cedo demais ou tarde demais?
2. a aproximacao parece lenta ou agressiva?
3. o golpe e legivel?
4. o ataque parece justo?
5. 3 golpes para derrota parece pouco, bom ou muito?
6. 20 de dano parece ameaçador?
7. e possivel entender os estados sem olhar o texto de debug?

## Proximo passo sem playtest
Criar o Estagiario Atirador em estrutura separada, mas nao integrar o encontro combinado definitivamente antes de validar o Espadachim.
