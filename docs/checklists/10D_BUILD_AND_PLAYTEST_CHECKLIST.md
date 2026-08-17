# 10D Build & Playtest Checklist

## Pre-build

- [ ] Baseline 9.5 preservada.
- [ ] Branch de integração criada.
- [ ] Blueprint 10C-B8 aplicado ao greybox.
- [ ] Player Start configurado.
- [ ] Encounter Trigger configurado.
- [ ] Exit Door configurada.
- [ ] Spawn A/B/C configurados.
- [ ] Greybox antigo preservado ou comparável.

## Navigation / Collision

- [ ] Player contorna balcão.
- [ ] Player circula 360° nos pilares.
- [ ] Grupo atravessa o choke.
- [ ] Aliados recuperam caminho após obstáculo.
- [ ] Inimigos contornam balcão e pilares.
- [ ] Porta LOCKED bloqueia nav.
- [ ] Porta OPEN libera nav.

## Projectile

- [ ] Espaço aberto = PASS.
- [ ] Parede = BLOCK.
- [ ] Pilar = BLOCK.
- [ ] Balcão = BLOCK.
- [ ] Porta CLOSED/LOCKED = BLOCK.
- [ ] Porta OPEN = PASS.
- [ ] Banco = PASS inicialmente.
- [ ] Divisória = definir após asset físico.

## Encounter

- [ ] ROOM_IDLE ao carregar.
- [ ] Trigger dispara uma única vez.
- [ ] ROOM_COMBAT inicia.
- [ ] 2 melee no Spawn A.
- [ ] 1 ranged no Spawn B.
- [ ] 1 melee no Spawn C.
- [ ] Inimigos registrados corretamente.
- [ ] Mortes removem da contagem.
- [ ] PendingSpawns impede conclusão prematura.
- [ ] ROOM_COMPLETE ocorre corretamente.
- [ ] Exit OPEN ao concluir.
- [ ] Restart retorna a ROOM_IDLE.

## Playtest

- [ ] 3 runs internas sem alterar balanceamento no meio.
- [ ] Encounter Duration registrada.
- [ ] Mortes e causas registradas.
- [ ] Bugs possuem localização/reprodução.
- [ ] P0/P1 identificados.
- [ ] Resultado: GO / ITERATE / NO-GO.
