# O Cavaleiro Executivo — RC2 QA Checklist

Use este checklist para o smoke test final da Release Candidate 2.

## Gate P0 — bloqueia release

- [ ] O jogo inicia sem erro fatal.
- [ ] Vídeo/intro pode ser concluído ou pulado e entrega ao Menu Principal.
- [ ] NOVO JOGO entra no fluxo esperado.
- [ ] CONTINUAR/CARREGAR não causa crash ou soft-lock.
- [ ] Fase 00 pode ser concluída do início ao fim.
- [ ] Nenhum diálogo da Fase 00 ou Docas congela o input do jogo.
- [ ] Não é possível cair para fora das salas e permanecer em limbo.
- [ ] Docas do Armazém permite atravessar as 11 salas.
- [ ] Escadas das Docas permitem subir/descer e sair no topo sem salto residual descontrolado.
- [ ] Fase 01 continua acessível e completável conforme a progressão atual.
- [ ] Save/load preserva desbloqueios e `prologue_cleared`.

## Gate P1 — bloqueia promoção se reproduzível

- [ ] Troca entre protagonista e companions funciona durante gameplay.
- [ ] Companion não controlado não entra em loop de morte por queda.
- [ ] Projéteis não atravessam plataformas que devem bloqueá-los.
- [ ] Inimigos não cometem suicídio ao ativar/entrar na área.
- [ ] Gates lógicos da Fase 01 não podem ser burlados por respawn/checkpoint.
- [ ] HUD de HP e cooldown permanece legível e sincronizado.
- [ ] Seleção de personagens respeita bloqueios/desbloqueios.
- [ ] Fases gated respeitam o personagem obrigatório.
- [ ] Vitória de boss não perde progresso ao retornar à seleção de fases.

## Regressão das fases de boss

- [ ] Caverna inicia e permite combate.
- [ ] Ruínas/Necromante inicia e seus interlúdios não travam.
- [ ] Floresta/Satyr inicia e pode ser vencida.
- [ ] Cemitério/Ogro inicia e pode ser vencido.
- [ ] Noite Estrelada/Morcego inicia e pode ser vencida.
- [ ] Covil do Tesouro/Dragão respeita gating e mecânica da ponte.

## Fase 00 — inspeção visual rápida

- [ ] Cafeteira e NPC da cafeteria não se sobrepõem à escada decorativa.
- [ ] Caixa de diálogo comporta falas longas sem cortar conteúdo crítico.
- [ ] NPCs/props não criam bloqueios físicos inesperados.

## Docas do Armazém — inspeção de travessia

- [ ] Bordas esquerda/direita de todas as salas estão protegidas.
- [ ] Escadas de L01, L04, L07, L09 e L10 têm entrada/saída consistente.
- [ ] Não há queda infinita ao atravessar transições de sala.
- [ ] L06 e L11 não causam soft-lock nos beats de diálogo atuais.

## Classificação de defeitos

- **P0**: crash, save corrompido, hard-lock, fase impossível, progressão perdida.
- **P1**: soft-lock reproduzível, mecânica principal quebrada, gate burlável, queda em limbo.
- **P2**: comportamento incorreto com workaround simples, problema visual relevante.
- **P3**: polish, alinhamento, texto, animação ou inconsistência cosmética.

## Resultado da rodada

- Build/commit testado: ______________________________
- Plataforma: ________________________________________
- P0 encontrados: ____________________________________
- P1 encontrados: ____________________________________
- P2/P3: _____________________________________________
- Resultado: [ ] GO  [ ] ITERATE  [ ] NO-GO
- Observações: ________________________________________
