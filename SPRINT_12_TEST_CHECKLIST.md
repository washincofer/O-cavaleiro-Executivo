# Sprint 12 — Checklist de Playtest

- [ ] `1` inicia no Guerreiro; `2` na Arqueira; `3` na Maga.
- [ ] Os tres tem sprite/animacao reais (idle/andar/pular/cair) e viram
      (flip) corretamente ao trocar de direcao com `A`/`D`.
- [ ] Com qualquer slot ativo, `J` executa o ataque daquele personagem
      (corpo a corpo para o Guerreiro; flecha/orbe para Arqueira/Maga).
- [ ] A flecha da Arqueira usa o sprite real e e destruida ao acertar
      inimigo ou colidir com o cenario.
- [ ] O orbe da Maga viaja em linha reta e e destruido nas mesmas condicoes.
- [ ] Rato e Gosma perseguem o personagem ativo, atacam em alcance e tem
      animacao de hurt/death ao serem derrotados.
- [ ] Auto Handoff troca para o proximo aliado vivo quando o ativo morre.
- [ ] Seguidores inativos ficam imunes a dano e a queda fatal; ao cair,
      sao reposicionados perto do lider (`RESGATE DE FOLLOW`).
- [ ] As 3 plataformas elevadas sao alcancaveis com salto normal (sem
      escada).
- [ ] HUD mostra `inimigos X/2` e some para `AREA LIMPA` ao derrotar os
      dois inimigos.
- [ ] `GAME OVER` aparece se os 3 membros forem derrotados; `R` reinicia.
- [ ] Chao/paredes usam a textura do Pixel Cave Tileset (sem tiles
      transparentes/quebrados nas bordas das plataformas).
