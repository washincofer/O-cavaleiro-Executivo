# Sprint 1 — Fundacao de Combate

## Objetivo
Avancar o laboratorio sem depender do primeiro playtest de movimentacao.

## Implementado por DEV
- ataque basico no J
- janela ativa de hitbox separada da duracao total do ataque
- dano base do Cavaleiro: 10
- HP do Cavaleiro: 100
- hurtbox do Cavaleiro preparada para inimigos futuros
- invulnerabilidade curta apos receber dano
- dummy de combate com 30 HP (3 golpes)
- knockback simples no dummy
- feedback visual temporario de acerto
- HUD simples de HP

## Valores provisórios — NAO FINALIZADOS
- ataque total: 0,28 s
- janela ativa: 0,07 s a 0,16 s
- cooldown do ataque: 0,22 s
- dano: 10
- invulnerabilidade apos dano: 0,45 s

Estes valores devem ser ajustados somente depois do primeiro playtest em PC.

## Trabalho de DG
Foi criada `scenes/art/scale_reference.tscn` como referencia tecnica de proporcao:
- Estagiario: 44 px
- Espadachim: 48 px
- Cavaleiro Executivo: 48 px
- Coordenador: 60 px

A cena nao representa arte final, apenas escala e hierarquia visual.

## Proximo passo sem playtest
1. Criar base reutilizavel de inimigo.
2. Implementar Mercenario Espadachim com maquina de estados simples.
3. Manter numeros de velocidade/alcance como provisórios.
4. Nao iniciar arte final ate validar o controle e o combate em PC.

## Checkpoint quando houver acesso ao PC
Validar em ordem:
1. corrida e parada
2. altura e resposta do pulo
3. distancia do dash
4. alcance do ataque
5. sensacao de acertar o dummy
6. tempo para 3 golpes consecutivos
7. camera

Registrar apenas: bom / lento / rapido / curto / longo / confuso.
Nao e necessario medir numeros no primeiro teste.
