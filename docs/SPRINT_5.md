# Sprint 5 — Sequencia Completa da Recepcao (Opcional)

## Objetivo
Conectar os tres arquetipos em uma versao opcional da Sala de Prototipo 01 sem substituir a cena principal de teste.

## Cena criada
`scenes/dev/reception_full_test.tscn`

Ela NAO e a cena principal do projeto. Serve como preview tecnico do encontro completo quando houver acesso ao PC.

## Fluxo implementado
### Fase 1
1 Mercenario Espadachim.

Quando morre, pequena pausa.

### Fase 2
1 Mercenario Espadachim + 1 Estagiario Atirador.

O Estagiario nasce na plataforma elevada da Recepcao.

Quando os dois morrem, pequena pausa.

### Fase 3
1 Coordenador de Contencao.

Quando morre:
- encontro e concluido
- porta final e liberada
- aparece `ACESSO EXECUTIVO AUTORIZADO`

## Porta
A saida fica fisicamente bloqueada durante o encontro.
A colisao e desativada somente depois da derrota do Coordenador.

## Posicoes atuais — PROVISORIAS
- Cavaleiro: x 48
- Espadachim Fase 1: x 315
- Espadachim Fase 2: x 545
- Estagiario Fase 2: x 480 na plataforma
- Coordenador: x 765
- Porta: x 900

## Por que esta cena nao virou `main.tscn`
Ainda precisamos validar primeiro:
- movimento
- ataque
- dummy
- Espadachim isolado

A cena completa existe para acelerar o proximo ciclo, mas nao deve orientar balanceamento antes desses testes.

## Estado do laboratorio neste ponto
DEV ja possui:
- protagonista funcional provisório
- fundacao de combate
- dummy
- Espadachim
- Estagiario
- projétil
- Coordenador
- sequenciador de encontro
- condicao de vitoria

DG ja possui referencias tecnicas para:
- escala geral
- Espadachim
- Estagiario
- Coordenador

## Proxima prioridade
Parar de adicionar sistemas de combate ate o primeiro playtest.

Enquanto o playtest nao acontece, o avanço mais seguro e:
1. guia visual do Cavaleiro Executivo
2. linguagem visual da Recepcao
3. paleta provisoria
4. lista de animacoes necessarias
5. especificacao de UI do laboratorio

Sem produzir arte final ainda.
