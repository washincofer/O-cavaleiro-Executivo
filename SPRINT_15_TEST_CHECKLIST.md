# Sprint 15 — Checklist de Playtest

## Sistema de desbloqueio + cutscene

- [ ] Na selecao livre (Ruinas/Floresta/Cemiterio/Noite Estrelada), Paladino,
      Cavaleiro e Heroina da Ponte aparecem escurecidos com o texto
      "BLOQUEADO" e nao podem ser clicados.
- [ ] Ao vencer o boss da Floresta (Satyr), a tela troca para uma cutscene
      anunciando "NOVO PERSONAGEM DESBLOQUEADO! PALADINO" com uma pequena
      animacao de entrada do retrato.
- [ ] Clicar CONTINUAR (ou apertar qualquer tecla) na cutscene volta para a
      selecao de fase.
- [ ] Voltando a qualquer fase de selecao livre, o Paladino agora aparece
      liberado (retrato normal, clicavel) na grade.
- [ ] O mesmo fluxo funciona vencendo o Cemiterio (libera o Cavaleiro) e a
      Noite Estrelada (libera a Heroina da Ponte).
- [ ] Vencer a Ruinas (Necromante) continua sem cutscene — volta ao
      comportamento antigo (ESC/R).

## Efeitos de impacto

- [ ] Todo golpe que acerta (ataque corpo a corpo, flecha/projetil, rajada
      em area, golpe especial do boss) mostra um flash branco/laranja no
      ponto de impacto, na altura do torso do alvo.

## Fase: Floresta (boss Satyr)

- [ ] Fundo mostra uma clareira de floresta com arvores e o chao usando o
      pack seamless_patterns.
- [ ] O Satyr e um chefe unico gigante, sem outros inimigos na sala.
- [ ] "H" durante o aviso de investida interrompe e causa dano bonus.
- [ ] Vencer libera o Paladino.

## Fase: Cemiterio Gotico (boss Ogro)

- [ ] Fundo mostra um cemiterio noturno (lua, estrelas, tumulos, arvore
      seca).
- [ ] O Ogro e um chefe unico gigante; golpe de area e um "pisao" mais
      lento e telegrafado que o das outras fases.
- [ ] Vencer libera o Cavaleiro.

## Fase: Noite Estrelada (boss Morcego)

- [ ] Fundo usa o pack starry_night (ceu roxo, lua, nuvens, arvore
      laranja/vermelha).
- [ ] O Morcego aparece flutuando bem acima do chao, nunca parado (asas
      sempre batendo), com um mergulho rapido como golpe de area.
- [ ] Vencer libera a Heroina da Ponte.

## Fase: Covil do Tesouro (boss Dragao, fase gated)

- [ ] Antes de vencer a Noite Estrelada, o tile "COVIL DO TESOURO" na
      selecao de fase aparece escurecido com "TRANCADA"; passar o mouse
      mostra "REQUER: HEROINA DA PONTE" no preview grande. Clicar nao faz
      nada.
- [ ] Depois de liberar a Heroina da Ponte, o tile fica jogavel normalmente
      (arte colorida, brilho pulsante).
- [ ] Ao entrar na selecao de personagem desta fase, a Heroina da Ponte ja
      aparece escolhida e NAO pode ser removida do grupo (clicar nela nao
      faz nada); os outros 2 slots sao livres.
- [ ] Na fase, ha um vao real no chao entre o grupo e o Dragao. Cair nele
      mata o personagem ativo.
- [ ] A especial (H) da Heroina da Ponte perto do vao cria uma ponte
      temporaria (alguns segundos, pisca antes de sumir) que pode ser
      atravessada a pe.
- [ ] Do outro lado, o Dragao e um chefe unico gigante parado no lugar, com
      um sopro de fogo em area interrompivel com H.
- [ ] Vencer NAO libera nenhum personagem novo (fase final da sequencia).

## Regressao

- [ ] Fluxo completo Caverna (Sprint 12) continua sem regressao.
- [ ] Ruinas (Necromante) continua jogavel normalmente, com Paladino/
      Cavaleiro/Heroina disponiveis SE ja desbloqueados.
- [ ] Controles touch continuam aparecendo em todas as fases novas quando
      o dispositivo tem touchscreen.
