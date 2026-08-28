# O Cavaleiro Executivo — Sprint 14

## Objetivo

Trocar o placeholder do boss da fase Ruinas por um sprite de verdade
(Necromante), expandir o elenco jogavel com Paladino e Cavaleiro (fora do
sistema de categorias da Caverna), refazer a barra de vida e os nomes dos
personagens com o pack Medieval Free, e tornar o jogo jogavel em
touchscreen/mobile.

## Necromante substitui o Golem (Ruinas)

O pack `Necromancer` trouxe sprites reais (Idle/Walk/Attack/GetHit/Death) —
o boss da fase Ruinas deixou de ser a Gosma ampliada (stand-in da Sprint 13)
e passou a usar o role `necromancer` em `platform_actor_12.gd`, com escala
1.75 calibrada pelo bbox alpha do frame de Idle. O `ROLE_MODULATE` (tinta
permanente usada so pelo placeholder do Golem) foi esvaziado — a arte real
nao precisa de recolorizacao. `platform_boss_12.gd` teve a variavel/textos
renomeados de "Golem"/`golem` para "Necromante"/`boss_actor`.

## Novos personagens jogaveis: Paladino e Cavaleiro

Ambos usam uma habilidade especial (H) que reaproveita mecanicas ja
existentes — Cavaleiro faz a mesma investida do Guerreiro (`_start_charge`),
Paladino reaproveita a rajada em area do Mago de Fogo (`_cast_fire_burst`/
`fire_burst_from`) — sem precisar de nenhuma logica nova no boss, ja que a
interrupcao do windup so verifica "uma especial foi ativada", nao qual.

Como nenhum dos dois pertence as 3 categorias de mecanica da Provacao do
Trio (quebrar entulho / atravessar barreira / teleportar), eles **so
aparecem nas fases de boss**, nunca na selecao da Caverna. Isso motivou uma
2a forma de selecao:

### Selecao "livre" vs "por categoria"

`PartySelection12` ganhou `selection_mode` (`"categorized"` ou `"free"`),
escolhido por `stage_select_12.gd` de acordo com a fase clicada (Caverna =
categorized, fases de boss = free). Em modo livre, `character_select_12.gd`
mostra uma grade 4x2 com os 8 personagens do elenco completo; clicar
adiciona/remove do grupo (`PartySelection12.toggle_free_role`) ate o limite
de 3 (`FREE_PARTY_SIZE`). `get_party_roles()` passa a olhar o modo atual
antes de decidir se le `selection` (por categoria) ou `free_roles` (livre).

## UI: barra de vida e nomes (pack Medieval Free)

`assets/UI/Runtime/MedievalFree/health_bar.png` (recortado de
`MediavelFree.png`) substitui os `ColorRect` de vida desenhados a mao:

- **Por personagem** (`platform_actor_12.gd::_draw()`): a barrinha acima da
  cabeca agora desenha essa textura via `draw_texture_rect` e cobre a fatia
  sem vida com um retangulo escuro (a arte so vem 100% cheia, sem variante
  vazia) — a mesma logica "esvaziar da direita pra esquerda" usada na
  barra grande do boss desde a Sprint 13.
- **Nomes**: os nameplates ganharam a fonte MedievalSharp, contorno preto
  (legibilidade contra fundos variados) e centralizacao num box de largura
  fixa, em vez de texto solto alinhado a esquerda.
- **Boss** (`platform_boss_12.gd`): o fundo da barra virou um
  `NinePatchRect` (preserva as pontas arredondadas ao esticar) da mesma
  textura; `boss_bar_fill` virou `boss_bar_empty`, a mesma tecnica de
  cobrir a fatia vazia.

Um reskin mais profundo de paineis/botoes dos menus (usando os icones de
botao e cantoneiras do mesmo pack) ficou fora do escopo desta sprint —
seria a proxima extensao natural do `MediavelFree.png` ja integrado.

## Jogavel em touchscreen/mobile

- `scripts/playtest/touch_controls_12.gd` + `scenes/playtest/touch_controls_12.tscn`:
  7 `TouchScreenButton` (mover esquerda/direita, pular, atacar, especial,
  dash, pausar) usando `visibility_mode = VISIBILITY_TOUCHSCREEN_ONLY` — o
  proprio Godot os esconde em desktop/mouse, sem deteccao manual de
  plataforma. Cada botao aponta pelo `action` direto para a acao do
  InputMap ja usada pelo teclado (`move_left`, `jump`, `special`,
  `ui_cancel`, etc.), entao nenhum script de gameplay precisou mudar.
  Instanciado no HUD de `platform_party_12.gd` e `platform_boss_12.gd`.
- Icones: pack "Controller Icons" (Casper Gaming, arte de **Fauster** —
  credito exigido pelos termos do pack) recortados de `icons-controller.png`
  (grade 32x32) para `assets/UI/Runtime/TouchControls/`.
- `project.godot`: `window/handheld/orientation` estava fixo em **retrato**
  (valor 1, resquicio da configuracao inicial) — corrigido para
  **paisagem** (0), correto para um platformer 320x180 (16:9).
- `company_intro_12.gd`: a deteccao generica de "qualquer tecla/clique/
  toque" via `_unhandled_input` se mostrou pouco confiavel especificamente
  durante a reproducao do video em contextos touch (`InputEventScreenTouch`
  as vezes nao chegava a disparar o pulo, mesmo com o handler correto). Um
  botao real "PULAR >>" (`Button`, Control nativo) foi adicionado como
  caminho garantido — Controls nativos respondem a touch de forma
  confiavel (confirmado testando os botoes da propria selecao de fase sob
  o mesmo contexto), diferente de checar o tipo do evento bruto durante
  video.

### Bug corrigido: texturas grandes demais para WebGL/mobile

Ao testar a integracao do Necromante/Paladino num contexto com emulacao de
touch, o console acusou `WebGL: INVALID_VALUE: texImage2D: width or height
out of range` — 6 spritesheets (Attack2/Death/Attack do Paladino, Attack/
Death/Idle do Necromante) excediam 4096px de largura (ate 10080px), o
limite de textura comum em GPUs mobile/WebGL. Foram reamostrados para no
maximo 3840px de largura (linspace uniforme sobre os frames originais,
preservando a resolucao nativa de cada frame) e os `count`/`fps` em
`platform_actor_12.gd` foram ajustados para manter a mesma duracao real de
cada animacao. Sem esse ajuste, essas animacoes falhariam silenciosamente
(textura invalida) em varios celulares reais, nao so no teste automatizado.

## Arquivos

- `assets/Enemies/Necromancer/Runtime/` — sprites reais do boss da Ruinas.
- `assets/Characters/Paladin/Runtime/`, `assets/Characters/Knight/Runtime/`
  — novos personagens jogaveis (Cavaleiro reaproveita o zip Knight.rar da
  Sprint 13, antes descartado).
- `assets/UI/Runtime/Portraits/{paladin,knight}.png` — retratos.
- `assets/UI/Runtime/MedievalFree/health_bar.png` — barra de vida real.
- `assets/UI/Runtime/TouchControls/*.png` — icones dos botoes virtuais.
- `scripts/playtest/touch_controls_12.gd` + `scenes/playtest/touch_controls_12.tscn`
  — controles virtuais reusaveis entre as fases.
- `scripts/playtest/platform_actor_12.gd` — roles `necromancer`/`paladin`/
  `knight`; barra de vida e nameplate com a nova UI.
- `scripts/playtest/platform_boss_12.gd` — Necromante no lugar do Golem;
  barra do boss com `NinePatchRect`; textos de Paladino/Cavaleiro.
- `scripts/globals/party_selection_12.gd` — `selection_mode`/`free_roles`/
  `toggle_free_role`.
- `scripts/menu/character_select_12.gd` — grade de selecao livre (8
  personagens, ate 3 escolhidos) para as fases de boss.
- `scripts/menu/stage_select_12.gd` — `selection_mode` por fase.
- `scripts/menu/company_intro_12.gd` — botao "PULAR" nativo.
- `project.godot` — orientacao paisagem.

## O que testar

Veja `SPRINT_14_TEST_CHECKLIST.md`.
