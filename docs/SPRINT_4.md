# Sprint 4 — Coordenador de Contencao (Sistema Isolado)

## Objetivo
Estruturar o terceiro arquetipo do laboratorio sem coloca-lo ainda no fluxo oficial da Recepcao.

## Implementado por DEV
- Coordenador com 70 HP
- maquina de estados:
  - IDLE
  - ALERTA
  - AVANCAR
  - PREPARAR
  - ESMAGAR
  - RECUPERAR
  - MORTO
- avanco lento e constante
- maça/clava pneumática provisoria
- telegraph longo com indicador de pressao
- golpe pesado com pequeno avanco
- 35 de dano provisório
- recuperacao longa de 1,02 s
- super-armadura simples: ataques comuns causam dano, mas nao interrompem suas acoes
- knockback recebido reduzido para 16%
- cena isolada `scenes/dev/coordinator_test.tscn`

## Valores atuais — TODOS PROVISORIOS
- vida: 70
- deteccao: 210 px
- velocidade: 46 px/s
- alcance: 43 px
- preparacao: 0,86 s
- ataque ativo: 0,16 s
- recuperacao: 1,02 s
- dano: 35
- knockback recebido: 16% do normal

## Filosofia validada em codigo
O Espadachim pede REACAO.
O Estagiario pede PERSEGUICAO.
O Coordenador pede PACIENCIA.

A diferenca ja existe no comportamento, nao apenas nos numeros.

## Trabalho de DG
Criada `scenes/art/coordinator_silhouette_reference.tscn`.

Diretrizes:
- aproximadamente 60 px
- silhueta larga
- barba por fazer
- postura cansada e pesada
- roupa/armadura operacional gasta
- maça pneumática muito legivel
- identificacao discreta de Coordenador
- humor vem do cargo e do contexto, nao de caricatura

## O que NAO foi implementado ainda
- buff real em subordinados
- ordens para outros inimigos
- segundo ataque
- voz/falas
- animacoes finais

A influencia hierarquica fica registrada para iteracoes futuras.

## Checkpoint futuro no PC
1. o golpe parece assustador antes de acontecer?
2. 0,86 s e tempo suficiente para reagir sem ficar lento demais?
3. a super-armadura parece peso ou injustica?
4. 1,02 s de recuperacao gera uma abertura clara?
5. 7 golpes para derrota cansam?
6. 35 de dano gera respeito sem ser punitivo demais?

## Proximo passo recomendado
Nao adicionar novos inimigos.
O proximo avanço seguro sem playtest e montar a logica do encontro da Sala 01 com os tres sistemas atras de fases/gatilhos, mantendo uma chave de debug para testar cada fase separadamente.
