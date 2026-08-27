# O Cavaleiro Executivo — Sprint 12

## Objetivo

Substituir os placeholders desenhados a mao (circulos/linhas) do laboratorio
de plataforma por asset packs reais, mantendo a arquitetura de party/camera/
seguidores validada nas sprints 11B/11C.

## Asset packs integrados

| Pack | Uso | Licenca |
| --- | --- | --- |
| Wizard Pack | Maga (slot 3) | CC0 |
| Huntress 2 | Arqueira (slot 2), incluindo o sprite da flecha | CC0 |
| Medieval Warrior Pack 3 | Guerreiro (slot 1) | CC0 |
| Monsters Creatures Fantasy 2 | Inimigos Rato e Gosma (Slime) | Mesmo autor/estilo dos packs acima; sem `License.txt` no zip — trate como os demais ate confirmacao explicita antes de uso comercial fora deste prototipo |
| Pixel Cave Tileset (NamiPixels) | Piso/parede da caverna (`cave_tileset.png`) | Uso comercial/nao comercial permitido; **nao pode ser revendido/redistribuido como asset pack** |

Os arquivos usados ficam em `assets/Characters/<Nome>/Runtime/`,
`assets/Enemies/<Nome>/Runtime/` e `assets/Environment/Cave/Runtime/`,
seguindo a convencao Runtime/Source ja usada por Espadachim/Estagiario/
Coordenador (`assets/README_ASSETS.md`). Somente os spritesheets
efetivamente usados pelo jogo foram copiados (idle/run/attack/hit/death
+ jump/fall para os 3 personagens jogaveis; idle/walk-run/attack/hurt/
death para os inimigos); previews, `.gif` e `License.txt` dos packs não
foram copiados para Runtime.

## Party do laboratorio

1. **GUERREIRO** (Medieval Warrior Pack 3) — ataque corpo a corpo.
2. **ARQUEIRA** (Huntress 2) — ataque a distancia com flecha real (sprite
   `Sprites/Arrow/Move.png`).
3. **MAGA** (Wizard Pack) — ataque a distancia com um orbe magico
   desenhado (a Wizard Pack nao inclui um sprite solto de feitico).

Os tres agora sao simetricos: qualquer um, quando controlado (`1`/`2`/`3`),
pode atacar com `J`. Isso substitui o desenho antigo em que so o Cavaleiro
lutava e os demais eram companions utilitarios.

## Inimigos (Monsters Creatures Fantasy 2)

- **RATO** — mordida corpo a corpo, HP baixo, rapido.
- **GOSMA** (Slime) — ataque corpo a corpo, mais lento, HP baixo.

Ambos usam a mesma IA terrestre da 11C (persegue o personagem ativo,
nao pula voluntariamente em vao fatal, ataca em alcance) com animacoes
reais (idle/andar/ataque/hurt/death via `AnimatedSprite2D`) no lugar dos
circulos coloridos.

## Cenario (Pixel Cave Tileset)

- Piso e plataformas usam `cave_tileset.png` (tile 16x16, variante cinza
  cheia) pintado via `TileMapLayer` sobre as MESMAS colisoes retangulares
  da 11B.1 — a fisica de salto/vao nao mudou.
- O fundo da caverna usa o mesmo tileset com um tom mais escuro
  (`modulate`) para dar profundidade sem precisar de uma segunda imagem.

## Mecanicas ajustadas em relacao a 11C

- **Removida a mecanica de escada** (`AUXILIAR ESCADA`): era um placeholder
  explicitamente provisorio e nao faz parte do kit Guerreiro/Arqueira/Maga.
- A plataforma central, que antes exigia a escada (~108px acima do chao),
  agora fica na mesma altura das outras duas (~34px), alcancavel por um
  salto normal — sem isso ela ficaria permanentemente inacessivel.
- Condicao de conclusao trocada de "puzzle da escada" para **derrotar os
  dois inimigos da caverna** (`active_enemies <= 0`), mostrado no HUD.
- Dano/curva de combate: cada ataque (corpo a corpo ou a distancia) respeita
  um cooldown proprio por personagem (Guerreiro 0.45s, Arqueira/Maga
  idem — configuravel em `ROLE_BODY` de `platform_actor_12.gd`).
- Mantido sem alteracao: selecao 1/2/3, Auto Handoff, seguidores protegidos
  contra dano/queda fatal enquanto inativos + resgate automatico, dash,
  camera lateral, restart.

## Selecao de fase, loading e pausa

- `run/main_scene` agora aponta para `scenes/menu/stage_select_12.tscn` —
  um grid de 8 slots no estilo do menu de robos-mestres da saga Mega Man.
  Só a **CAVERNA** (esta sprint) esta liberada, com preview real da fase;
  os outros 7 slots ficam com placeholder `?` desabilitado ("EM BREVE"),
  para as proximas fases entrarem aos poucos.
- Clicar na fase liberada leva a `scenes/menu/loading_screen_12.tscn`,
  uma tela de loading artificial de ~3s (barra de progresso via `Timer`
  simulado em `_process`) antes de carregar a fase de verdade — mesmo ela
  carregando quase instantaneamente.
- Dentro da fase, as instrucoes completas (objetivo + controles) saíram
  do HUD fixo e só aparecem ao pressionar **ESC**, que pausa o jogo
  (`get_tree().paused`) e mostra um menu com **CONTINUAR** e **VOLTAR A
  SELECAO DE FASE**. A deteccao de ESC usa um watcher dedicado
  (`pause_watcher_12.gd`, `process_mode = ALWAYS`) para continuar
  funcionando mesmo com a arvore pausada.

## Puzzle e desafio

- **Puzzle**: um interruptor (`platform_switch_12.gd`) fica suspenso no
  vao entre a plataforma B e C (x 760–800), fora do alcance do ataque
  corpo a corpo — só um projetil (flecha da Arqueira ou orbe da Maga)
  disparado do fim da plataforma B o acerta. Isso reusa o mesmo
  `try_projectile_hit` já usado para inimigos.
- Acertar o interruptor remove um **portao magico** (barra roxa,
  colisao + visual) que bloqueia a entrada da plataforma C.
- **Desafio**: atras do portao, a **GOSMA REAL** tem o dobro de HP
  (6 em vez de 3) de um inimigo comum — reforco reservado para quem
  resolve o puzzle.

## Nota tecnica

Durante a validacao deste sprint (Godot 4.4.1 headless, o mesmo binario
usado pelo `build_web.sh`) foi identificado que `platform_party_11b.gd` e
`platform_party_11c.gd` emitem `SCRIPT ERROR: Parse Error` num passe de
`GDScript::reload` (inferencia de tipo `:=` sobre `Array` sem tipo /
retorno de metodo dinamico). O `--export-release` da 11C ainda empacota
corretamente porque o bytecode já havia sido compilado num passe anterior,
mas rodar a cena diretamente (fora do fluxo de export) resulta em tela
em branco — o script falha ao anexar ao no raiz. Os scripts desta sprint
(`platform_party_12.gd`, `platform_actor_12.gd`, `platform_projectile_12.gd`)
foram escritos com `Array[Tipo]` e anotacoes de tipo explicitas para evitar
a mesma armadilha; os arquivos antigos das sprints 11B/11C nao foram
tocados (permanecem como registro historico).

## Arquivos

- `project.godot` — `run/main_scene` aponta para `scenes/menu/stage_select_12.tscn`.
- `scripts/build_web.sh` — basename de export atualizado para
  `cavaleiro-sprint12-v01`.
- `scenes/menu/stage_select_12.tscn` + `scripts/menu/stage_select_12.gd`
  — grid de selecao de fase estilo Mega Man.
- `scenes/menu/loading_screen_12.tscn` + `scripts/menu/loading_screen_12.gd`
  — tela de loading artificial (~3s) antes da fase.
- `scenes/playtest/platform_party_12.tscn` — cena da fase em si.
- `scripts/playtest/platform_party_12.gd` — mundo, party, inimigos, HUD,
  puzzle do portao e menu de pausa.
- `scripts/playtest/platform_actor_12.gd` — ator com `AnimatedSprite2D`,
  movimento, IA e combate.
- `scripts/playtest/platform_projectile_12.gd` — flecha (sprite real) e
  orbe magico (desenhado).
- `scripts/playtest/platform_switch_12.gd` — interruptor do puzzle.
- `scripts/playtest/pause_watcher_12.gd` — detecta ESC mesmo com a
  arvore pausada.
- `assets/UI/Runtime/stage_caverna_preview.png` — thumbnail da fase
  usada na tela de selecao.

## O que testar

Veja `SPRINT_12_TEST_CHECKLIST.md`.
