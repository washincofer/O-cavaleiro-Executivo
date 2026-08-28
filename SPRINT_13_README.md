# O Cavaleiro Executivo — Sprint 13

## Objetivo

Adicionar uma segunda fase jogavel (fundo diferente do Pixel Cave Tileset da
Sprint 12), estruturada como uma boss fight de sala unica no estilo Super
Kirby Clash, e uma tela de intro em video antes do fluxo de selecao de fase.

## Fundo novo: craftpix Post-Apocalyptic Pixel Art Backgrounds

| Pack | Uso | Licenca |
| --- | --- | --- |
| craftpix-901125-free-post-apocalyptic-pixel-art-game-backgrounds | Fundo da fase RUINAS | Craftpix free file license (https://craftpix.net/file-licenses/) — uso comercial/nao comercial permitido, nao pode ser revendido/redistribuido como asset pack |

O pack traz 4 cenarios (Postapocalypce1-4) em variantes Bright/Pale. Foi usado
o conjunto **Postapocalypce1/Bright** (choupanas destruidas sobre terra
rachada, ceu alaranjado dramatico) por combinar melhor com uma arena de boss
do que os outros (2 = cidade tomada pela natureza, 3 = deserto surreal a
noite, 4 = estacao de metro abandonada).

As camadas `clouds1`, `clouds2`, `ground&houses_bg`, `ground&houses` e
`ground&houses2` foram compostas em uma unica imagem estatica e
redimensionadas de 1920x1080 para 320x180 (fator exato de 6x, ja que ambas as
resolucoes sao 16:9) — a fase e uma sala unica sem scroll, entao a imagem
inteira cabe na tela sem necessidade de tiling. Resultado em
`assets/Environment/Ruins/Runtime/ruins_bg.png`. As camadas `road`/`fence`
(chao/cerca em close-up) nao foram usadas — o chao jogavel e desenhado por
codigo (retangulos solidos), como o resto do cenario "mecanico" do jogo
(portao, interruptor, entulho na Sprint 12).

## Golem: sem sprite proprio disponivel

O zip `Knight.rar` enviado para esta sprint contem **apenas** o personagem
Knight (Idle/Run/Attack/Death/JumpAndFall/Roll/Shield) — nenhum Golem, apesar
do pedido original mencionar um. `Monsters Creatures Fantasy 2` (Bat/Mimic/
Rat/Slime) tambem foi conferido e nao tem Golem. Perguntado como proceder, a
decisao foi: **reaproveitar a Gosma (Slime) como stand-in**, em escala bem
maior (`ROLE_BODY.golem.scale = 3.2`, contra `1.0` da Gosma comum) e com um
`modulate` acinzentado (`ROLE_MODULATE.golem`) para diferenciar visualmente
da Gosma verde comum, ate uma arte definitiva de Golem chegar.

`base_modulate` (novo campo em `platform_actor_12.gd`) guarda essa tinta
permanente por role e substitui os resets fixos para `Color(1,1,1)` em
`take_damage`/`_die`/`_on_animation_finished`, que agora restauram a tinta
correta em vez de branco puro — sem isso, a primeira vez que o Golem tomasse
dano (flash vermelho) ou morresse ele voltaria a ficar verde normal.

## A fase: RUINAS (`platform_boss_12.gd`)

Como as sprints anteriores, cada fase mantem seu **proprio controller**
(nao ha classe base compartilhada) — `platform_boss_12.gd` deriva a mesma
arquitetura de party/camera/seguidores/HUD/pausa de `platform_party_12.gd`,
mas e um arquivo independente com um mundo bem menor: uma **sala unica sem
scroll** (`WORLD_WIDTH = 320`, exatamente a largura do viewport, o que faz a
formula de camera existente — `clampf(x, 160, WORLD_WIDTH - 160)` — resultar
sempre em `160`, uma camera fixa "de graca") em vez do nivel longo com
puzzle de portao da Caverna. Duas plataformas elevadas (com um pilar de
apoio visual) dao ao grupo espaco para se reposicionar/desviar do golpe do
Golem.

O trio selecionado na tela de personagens (mesmo fluxo Smash Bros da Sprint
12 — nenhuma mudanca necessaria) enfrenta um unico inimigo: o **GOLEM DE
PEDRA**, com HP muito mais alto (60, contra 3-6 dos inimigos da Caverna).

## Boss fight estilo Super Kirby Clash

Em vez de handling especifico por personagem, a boss fight reaproveita a
**mesma tecla especial (H)** que ja existe para as 6 opcoes de personagem,
dando a ela um significado novo e universal nesta fase:

- A cada ~5s o Golem entra em **windup** (1.3s): o sprite pulsa entre a cor
  normal e vermelho de aviso, e o HUD mostra "GOLEM SE PREPARA PARA UM
  IMPACTO — INTERROMPA COM H!".
- Se o windup terminar sem interrupcao, o Golem desfere um **impacto em
  area** (raio 74px): qualquer personagem por perto leva 1 de dano e e
  arremessado para tras (knockback).
- Se QUALQUER personagem do grupo ativar sua habilidade especial (H)
  enquanto o windup esta ativo — Estocada, Rajada de Fogo, Tiro Perfurante
  ou Teleporte, nao importa qual — o golpe e **interrompido**: o Golem leva
  dano bonus (+6) e fica "atordoado" (o proximo windup demora mais para
  comecar, 7.5s em vez de 5s).

Essa mecanica funciona **identica para qualquer combinacao de 3 personagens**
escolhida na selecao — nenhuma logica por personagem foi adicionada ao boss;
o gancho fica inteiramente em `activate_actor_special()`
(`platform_boss_12.gd`), que ja e chamado para as 6 roles. Isso reaproveita
o design da Sprint 12 (uma mecanica unica por categoria) em vez de duplicar
regras: o "uso certo da habilidade certa" continua importando (mais
personagens ativos = mais chances de interromper, já que cada um tem seu
proprio cooldown de especial), mas o boss em si nao distingue Guerreiro de
Mago de Fogo.

O ataque de contato basico do Golem (dano de 1 quando adjacente, ja existente
em `platform_actor_12.gd::_enemy_tick()`) teve o cooldown aumentado para
1.3s (`golem.attack_cooldown_max`) para nao competir com o impacto em area
como a ameaca principal da luta.

### Validacao da mecanica de interrupcao

Testar a janela de 1.3s via clique/tecla simulados por Playwright provou ser
impreciso (latencia do navegador headless). A mecanica foi validada de forma
determinística com um script `scripts/dev/_boss_interrupt_temp.gd` (`extends
"res://scripts/playtest/platform_boss_12.gd"`, mesmo padrao de teste isolado
usado nas sprints anteriores) que chama `_start_slam_windup()` e
`activate_actor_special()` diretamente, confirmando: dano bonus aplicado
(60 -> 54 HP), `slam_windup` zerado e `slam_timer` ajustado para o valor de
atordoamento (7.5s). O script foi apagado apos o teste (nunca commitado).

## Selecao de fase: 2 fases desbloqueadas

`scripts/menu/stage_select_12.gd`: `STAGES` agora carrega `preview`,
`target_scene` e `loading_title` por fase em vez de um preview/destino fixo
global. A miniatura da RUINAS reaproveita `ruins_bg.png` diretamente (a
imagem ja e "so cenario", sem elementos de jogo desenhados nela). O autoload
`PartySelection12` ganhou `target_scene`/`loading_title`, setados por
`stage_select_12.gd` ao clicar em uma fase e lidos por `loading_screen_12.gd`
no lugar da constante fixa que so apontava para a Caverna. O brilho
pulsante do slot desbloqueado (antes so a Caverna) agora cobre todas as
fases desbloqueadas.

## Tela de intro da empresa (video)

`scenes/menu/company_intro_12.tscn` + `scripts/menu/company_intro_12.gd` —
nova cena definida como `run/main_scene` (antes da selecao de fase), que
toca o video enviado em tela cheia via `VideoStreamPlayer` e avanca para a
`stage_select_12.tscn` automaticamente ao terminar ou a qualquer tecla/clique
("clique ou aperte qualquer tecla para pular").

**Nota tecnica**: o Godot 4 so reproduz video nativamente em **Ogg Theora
(.ogv)** — nao ha suporte a mp4/h264 sem plugins externos. O video enviado
(`WhatsApp_Video_20260811_at_14.09.17.mp4`, H.264/AAC, 1280x720, 10s) foi
convertido via `ffmpeg -c:v libtheora -q:v 7 -c:a libvorbis -q:a 4` para
`assets/Video/Runtime/company_intro.ogv` (~4.7MB). Confirmado tocando de
verdade no export Web real (Playwright + Chromium), nao so no binario nativo
— a mesma cautela de sempre desde o bug da tela cinza da Sprint 12.

## Arquivos

- `project.godot` — `run/main_scene` aponta para
  `scenes/menu/company_intro_12.tscn`.
- `scenes/menu/company_intro_12.tscn` + `scripts/menu/company_intro_12.gd`
  — tela de intro em video.
- `assets/Video/Runtime/company_intro.ogv` — video convertido para Theora.
- `assets/Environment/Ruins/Runtime/ruins_bg.png` — fundo composto e
  redimensionado do craftpix Post-Apocalyptic.
- `scenes/playtest/platform_boss_12.tscn` + `scripts/playtest/platform_boss_12.gd`
  — fase da boss fight (mundo, party, Golem, HUD com barra de boss, pausa).
- `scripts/playtest/platform_actor_12.gd` — role `golem` (reaproveita
  animacoes da Gosma em escala maior) e `base_modulate`/`ROLE_MODULATE`
  para tingir o sprite permanentemente por role.
- `scripts/menu/stage_select_12.gd` — segunda fase (RUINAS) na grade,
  preview/destino por fase, brilho pulsante estendido a todas as
  desbloqueadas.
- `scripts/menu/loading_screen_12.gd` — le `PartySelection12.target_scene`/
  `loading_title` em vez de uma cena/texto fixos.
- `scripts/globals/party_selection_12.gd` — campos `target_scene` e
  `loading_title`.

## O que testar

Veja `SPRINT_13_TEST_CHECKLIST.md`.
