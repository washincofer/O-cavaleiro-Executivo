# Sprint 3 — Estagiario Atirador (Sistema Isolado)

## Objetivo
Avancar o segundo arquetipo sem alterar o encontro principal antes da validacao do Espadachim.

## Implementado por DEV
- Estagiario com 20 HP
- maquina de estados:
  - IDLE
  - ALERTA
  - MIRAR
  - DISPARAR
  - RECARREGAR
  - FUGIR
  - HIT
  - MORTO
- cancela mira e recarga quando o Cavaleiro se aproxima
- foge em direcao oposta ao jogador
- volta a mirar quando recupera distancia
- disparo interrompido por hit
- besta pneumatica provisoria
- virote pneumático como projétil real
- projétil causa 15 de dano
- projétil desaparece em colisao com o cenario
- cena isolada `scenes/dev/intern_test.tscn`

## Valores atuais — TODOS PROVISORIOS
- vida: 20
- deteccao: 235 px
- distancia de fuga: 82 px
- distancia confortavel: 126 px
- velocidade de fuga: 88 px/s
- mira: 0,78 s
- recarga: 0,72 s
- dano do projétil: 15
- velocidade do projétil: 170 px/s

## Decisao de seguranca de design
O Estagiario NAO foi colocado no `main.tscn`.

Motivo: o encontro combinado Espadachim + Estagiario so deve virar o fluxo oficial depois que o Espadachim isolado for validado no PC.

A cena `intern_test.tscn` existe para teste tecnico separado.

## Trabalho de DG
Criada `scenes/art/intern_silhouette_reference.tscn`.

Diretrizes:
- corpo ~44 px
- roupas leves
- pouca armadura
- besta pneumática relativamente grande
- cilindro de pressao claramente legivel
- cracha de estagiario
- postura visual mais defensiva/insegura que o Espadachim

## Checkpoint futuro no PC
1. o projétil e facil de enxergar?
2. 0,78 s de mira comunica bem o disparo?
3. a fuga parece covarde ou irritante?
4. e satisfatorio interromper o disparo?
5. 2 golpes para derrota parecem corretos?
6. o Estagiario cai da plataforma de modo aceitavel ou precisa de logica de borda?

## Proximo passo sem playtest
Estruturar o Coordenador em cena isolada com golpe pesado, super-armadura simples e grande janela de recuperacao.
