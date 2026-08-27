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
- [ ] Tela de selecao de fase abre no inicio; so a CAVERNA e clicavel,
      os outros 7 slots mostram `?` e nao reagem a clique.
- [ ] Clicar na CAVERNA mostra a tela de loading por ~3s antes de
      entrar na fase.
- [ ] Dentro da fase, `ESC` pausa o jogo e mostra objetivo + controles;
      `ESC` de novo (ou botao CONTINUAR) volta a jogar exatamente de
      onde parou.
- [ ] Botao "VOLTAR A SELECAO DE FASE" no menu de pausa volta para a
      tela de selecao (sem o jogo continuar rodando atras).
- [ ] Arvores do cenario aparecem inteiras (copa completa), nao pela
      metade ou cortadas.
- [ ] `H` executa uma habilidade DIFERENTE por personagem: Guerreiro
      investe (Estocada), Arqueira dispara uma flecha diferenciada (Tiro
      Perfurante), Maga conjura e se desloca (Teleporte).
- [ ] O ENTULHO na plataforma B bloqueia passagem a pe e ataque comum;
      so a Estocada do Guerreiro (`H` com ele ativo) o destroi.
- [ ] A barreira magica no vao 2 bloqueia flecha/orbe comuns (`J`) mas
      o Tiro Perfurante (`H` com a Arqueira) atravessa e acerta o
      interruptor, abrindo o portao roxo para a plataforma C1.
- [ ] O vao largo depois da C1 NAO e cruzavel com pulo duplo + dash; so
      o Teleporte da Maga (`H` com ela ativa, virada na direcao certa)
      atravessa ate a C2.
- [ ] O Teleporte nao atravessa o portao fechado nem paredes solidas
      (para antes delas em vez de passar direto).
- [ ] A GOSMA REAL na C2 tem HP visivelmente maior (6) que um inimigo
      comum.
