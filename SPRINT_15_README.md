# O Cavaleiro Executivo — Sprint 15

## Objetivo

Maior lote de conteudo do projeto ate aqui: sistema de desbloqueio de
personagens com cutscene de vitoria, efeitos de impacto (hit VFX) em todos
os pontos de dano, e **quatro fases novas de boss** (Floresta/Satyr,
Cemiterio Gotico/Ogro, Noite Estrelada/Morcego, Covil do Tesouro/Dragao),
cada uma liberando um heroi novo ao ser vencida — exceto a ultima, que e a
fase-final "gated": so pode ser jogada se um personagem especifico (a
Heroina da Ponte) ja estiver desbloqueado, porque so a mecanica exclusiva
dela (invocar uma ponte temporaria) permite atravessar o vao da sala.

## Sistema de desbloqueio de personagens

`PartySelection12` ganhou `unlocked_roles` (Array[String]): os 6 heróis
originais comecam liberados; Paladino, Cavaleiro e Heroina da Ponte comecam
bloqueados (`LOCKED_BY_DEFAULT`) e so entram na lista ao vencer o boss da
fase que os libera (`unlock_role`, chamado por `_handle_victory_reward()`
em cada controller de fase de boss). A grade de selecao livre
(`character_select_12.gd::_build_free_tile`) consulta `is_unlocked(role)`
por personagem: os ainda bloqueados aparecem na MESMA grade (layout fixo,
sem reorganizar a cada heroi liberado), escurecidos e com o texto
"BLOQUEADO", sem botao conectado — impossivel escala-los antes de
desbloquear.

Cada fase de boss com recompensa define `"reward_role"` no dicionario de
`stage_select_12.gd::STAGES`, copiado para
`PartySelection12.stage_reward_role` ao entrar na fase. Ao vencer, se esse
campo nao for vazio, `unlock_role()` roda e — so nesse caso — a fase troca
de cena para `victory_cutscene_12.tscn` apos 2.2s (tempo pra ler a mensagem
de vitoria) em vez de deixar o jogador sair pelo ESC/R como antes. A
cutscene (`scripts/menu/victory_cutscene_12.gd`, tela nova) le
`PartySelection12.last_unlocked_role`, mostra o retrato do heroi com uma
animacao de entrada (`Tween`: escala com `TRANS_BACK`+fade), e volta para a
selecao de fase ao clicar CONTINUAR ou apertar qualquer tecla. Fases sem
recompensa (Caverna, Ruinas, Covil do Tesouro) nunca usam esse fluxo — o
`stage_reward_role` fica vazio e o comportamento antigo (ESC/R) continua
identico.

Mapa de recompensas: **Floresta -> Paladino**, **Cemiterio -> Cavaleiro**,
**Noite Estrelada -> Heroina da Ponte**. O Covil do Tesouro (fase final) nao
libera ninguem — ele consome a Heroina da Ponte como pre-requisito de
acesso em vez de entregar mais um heroi.

## Efeitos de impacto (hit VFX)

`scripts/playtest/hit_effect_12.gd` + `scenes/playtest/hit_effect_12.tscn`:
um `AnimatedSprite2D` de 3 frames (spritesheet `hit.png` do pack "Explosions
and Magic", Legacy Collection) que roda uma vez e se destroi sozinho.
Instanciado direto em `Actor.take_damage()` (`platform_actor_12.gd`) — um
UNICO ponto de spawn cobre automaticamente todo dano do jogo (ataque corpo
a corpo, projetil, rajada em area, pancada/sopro/investida/mergulho/pisao
de qualquer boss), sem precisar tocar em nenhum dos callsites de dano
espalhados pelos controllers de cada fase.

## Quatro fases novas

Cada uma segue a mesma estrutura ja estabelecida nas Ruinas (Sprint 13/14):
sala unica sem scroll horizontal real (camera fixa no centro do mundo),
boss gigante com a mesma mecanica de golpe-em-area com aviso/interrupcao
(`slam_windup`/`_try_interrupt_slam`, reaproveitada 1:1, so com textos e
numeros proprios por fase), HUD com barra de vida do Medieval Free, e
controles touch. Selecao de personagem em modo "free" (grade completa,
qualquer 3).

### Floresta — boss Satyr

Pack `SATYR_sprite_sheet_` (320x352, grade 10x11 de 32x32) recortado por
linha: Idle (linha 0, 6 frames), Walk (linha 1, 8), Attack (linha 3, 7 —
golpe de espada), Hurt (linha 7, 4 — flash), Death (linha 6, 10). Escala
4.5 calibrada pelo bbox alpha do frame de Idle (creature nativa de 18x19px
dentro do canvas 32x32 — escala alta necessaria pra virar um "boss
gigante" coerente com o resto do elenco). Forest Monsters Free (pack citado
no pedido original) trouxe so um Cogumelo (o jogador pediu pra excluir),
entao — mesma solucao ja usada nas Ruinas quando um pack de "inimigos
regulares" saiu incompleto — a fase ficou boss-only.

Fundo (`forest_bg.png`) montado do zero com Python/PIL: gradiente de ceu,
arvores desenhadas proceduralmente, e o **pack seamless_patterns** (grade
32x32) fornecendo a textura de terra (tile "dirt/sand" tingido de
verde-acastanhado, ladrilhado) e uma faixa decorativa de "moitas com
frutinhas" na linha da grama — pedido explicito do usuario ("use o
seamless pattern para ajudar na criacao da nova fase").

### Cemiterio Gotico — boss Ogro

Pack Gothicvania (Legacy Collection), personagem `Ogre`: Idle (4 frames),
Walk (6), Attack (7, com um frame de rastro de movimento no golpe), todos
144x80 — sem Hurt/Death (o pack so trouxe essas 3). Escala 1.5, bbox de
idle 64x58 nativo. `_die()` ja tratava esse caso (sem animacao de morte, so
fica invisivel) desde o Cavaleiro (Sprint 14, sem "hurt"), entao nenhum
codigo novo foi necessario.

Fundo (`cemetery_bg.png`) tambem procedural: ceu noturno com lua e estrelas,
colinas distantes, arvore morta, e tumulos desenhados a mao (retangulos com
topo arredondado); o chao usa o mesmo pack seamless_patterns (tile de
pedra escura, tingido de azul para luz de lua).

### Noite Estrelada — boss Morcego

Pack `Monsters Creatures Fantasy 2`, criatura `Bat`: Fly (11 frames,
reaproveitada tanto como "idle" quanto "move" — um morcego nunca para de
bater as asas), Attack (11, mergulho com rastro), Hurt (3), Death (4),
todos 87x87. Escala 2.4. Como e uma criatura voadora, o offset visual (Ver
`ROLE_BODY["bat"]` em `platform_actor_12.gd`) flutua o sprite bem acima da
origem fisica do ator — a mesma tecnica ja usada pelos magos do grupo
(offset negativo grande), sem precisar de nenhuma fisica de voo nova: a
origem continua "presa" ao chao para fins de colisao/movimento, so o
desenho se move.

Fundo (`starry_night_bg.png`) usa os assets prontos do pack
`starry_night_by_quintino_pixels` quase sem alteracao — `background_sky.png`
(ceu roxo, lua atras de nuvem, estrelas) e `clouds.png` sobrepostos direto,
mais uma arvore recortada do `Tileset.png` do mesmo pack (paleta
roxo/laranja-fogo caracteristica) espalhada em duas escalas, e uma faixa de
chao no mesmo tom. Atendeu o pedido de "usar o starry night" quase que
diretamente, com o minimo de composicao extra.

### Covil do Tesouro — boss Dragao (fase final, com mecanica exclusiva)

Esta e a fase pedida explicitamente no briefing como "so jogavel se tiver
um personagem X desbloqueado, por causa de uma mecanica exclusiva":

- **Heroina da Ponte** (personagem jogavel novo): pack Gothicvania
  ("Bridge Heroine"), com Idle/Run/Attack/Jump (128x64, sem Hurt/Death — o
  mesmo caso ja tratado sem problemas). Escala 1.25. Ganhou uma habilidade
  especial **nova de verdade** (nao reaproveitada de outro personagem):
  `Actor._summon_bridge()` -> `controller.summon_bridge_from(actor)`.
- **Gating de fase**: `stage_select_12.gd::STAGES` ganhou
  `"required_role"`; `_is_stage_gated()` checa
  `PartySelection12.is_unlocked(required_role)`. Enquanto bloqueada, o
  tile mostra a arte escurecida com "TRANCADA" (em vez do "?" generico das
  fases ainda inexistentes) e o painel de preview mostra "REQUER: HEROINA
  DA PONTE" ao passar o mouse — o jogador entende O QUE falta, nao so que
  esta bloqueado.
- **Modo de selecao "gated"** (`PartySelection12.MODE_GATED`, novo, ao
  lado de "categorized"/"free"): igual ao modo livre, mas
  `toggle_free_role()` recusa remover o `required_role` do grupo — ele e
  forcado num dos 3 slots (`stage_select_12.gd::_on_stage_pressed` reseta
  `free_roles` para `[required_role]` ao entrar), garantindo que a mecanica
  exclusiva sempre esteja disponivel para resolver o vao da sala.
- **O vao**: `_add_ground_segment()` (em vez de um unico chao de ponta a
  ponta) cria duas plataformas — grupo aparece na esquerda, Dragao guarda
  o tesouro na direita — com um buraco real de 70px sem colisao nenhuma no
  meio. Cair nele mata o personagem ativo como qualquer poco de queda
  (`_check_falls`, ja existente desde a Caverna). `summon_bridge_from`
  constroi uma plataforma temporaria (`StaticBody2D` + retangulo visual de
  "tábua") cobrindo o vao por 6 segundos (pisca no ultimo 1.5s antes de
  sumir), tempo suficiente pra atravessar com folga.
- Nas outras 4 fases de boss, a mesma chamada
  (`controller.summon_bridge_from`) e um no-op inofensivo — mesmo padrao
  ja usado por `try_break_rubble` nas fases sem entulho — porque nenhuma
  delas tem vao para atravessar.
- Boss: Dragao (pack "Grotto-escape-2-boss-dragon", Gothicvania), Idle (6
  frames, reaproveitada como "move" — ele nunca sai do lugar, `"speed": 0`
  em `ROLE_BODY`) e Breath/sopro de fogo (7, usada como "attack"), 144x64,
  sem Hurt/Death. Escala 2.2.
- Fundo (`treasure_bg.png``) montado em camadas com os assets prontos do
  pack "treasure-hoard-platform" (Gothicvania): `background.png` (textura
  de parede tileavel), `back-gold.png` (colinas distantes) e `gold.png`
  (pilha de ouro com bau, camada de frente) — o mesmo autor ja tinha feito
  o trabalho de composicao visual, so precisou empilhar as camadas certas.

## Arquivos

- `assets/Enemies/{Satyr,Ogre,Bat,Dragon}/Runtime/` — sprites dos 4 bosses
  novos.
- `assets/Characters/BridgeHeroine/Runtime/` — Heroina da Ponte.
- `assets/Environment/{Forest,Cemetery,StarryNight,TreasureHoard}/Runtime/`
  — fundos das 4 fases novas.
- `assets/VFX/Runtime/hit_spark.png` — spritesheet do flash de impacto.
- `assets/UI/Runtime/Portraits/bridge_heroine.png` — retrato novo.
- `scripts/playtest/hit_effect_12.gd` + `scenes/playtest/hit_effect_12.tscn`
  — VFX de impacto reutilizavel.
- `scripts/playtest/platform_boss_{forest,cemetery,starrynight,treasurehoard}_12.gd`
  + cenas correspondentes — os 4 controllers de fase novos (cada um
  independente, seguindo a convencao das sprints anteriores).
- `scripts/playtest/platform_actor_12.gd` — roles `satyr`/`ogre`/`bat`/
  `dragon`/`bridge_heroine`; `_spawn_hit_effect()`; `_summon_bridge()`.
- `scripts/globals/party_selection_12.gd` — `unlocked_roles`/`unlock_role`/
  `is_unlocked`; `stage_reward_role`/`last_unlocked_role`; `required_role`
  e `MODE_GATED`.
- `scripts/menu/character_select_12.gd` — grade livre 3x3 (9 personagens)
  filtrando por `is_unlocked`; suporte ao modo "gated".
- `scripts/menu/stage_select_12.gd` — `reward_role`/`required_role` por
  fase; tile "TRANCADA" com motivo no preview.
- `scripts/menu/victory_cutscene_12.gd` + `scenes/menu/victory_cutscene_12.tscn`
  — tela nova de anuncio de personagem liberado.

## O que testar

Veja `SPRINT_15_TEST_CHECKLIST.md`.
