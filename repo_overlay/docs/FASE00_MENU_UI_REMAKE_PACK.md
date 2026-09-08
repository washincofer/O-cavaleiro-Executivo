# FASE 00 — Menu/UI/Remake Pack

Este pack foi preparado para **commit manual** e cobre os pontos pedidos:

## Escopo
- manter o fundo atual do menu inicial;
- trocar botão **Novo** pela UI **Iniciar**;
- trocar botão **Continuar** pela UI **Continuar**;
- posicionar **HUD de HP** no canto superior esquerdo;
- posicionar **HUD de Cooldown** no topo central;
- usar **balão de fala** e **tela de diálogo longo** para os textos;
- revisar **colisões da Fase 00** com escadas e plataformas;
- criar **tela de seleção de itens** ao apertar `Esc`;
- substituir o protagonista pelas **sprites atuais canônicas**;
- refazer a Fase 00 com estes pontos.

## O que vai no pack
### Assets
- `assets/Characters/CavaleiroExecutivo/Runtime/` com as sprites canônicas;
- `assets/UI/Runtime/CorporateUI/` com HUD e diálogo;
- `assets/UI/Runtime/CorporateUI/ButtonsV2/` com botões.

### Scripts-modelo
- `scripts/playtest/fase00_player_12.gd`
- `scripts/ui/main_menu_oce12.gd`
- `scripts/ui/fase00_hud_overlay_12.gd`
- `scripts/ui/fase00_dialogue_ui_12.gd`
- `scripts/ui/fase00_item_menu_12.gd`

## Ajustes manuais ainda necessários no projeto
1. Ligar `main_menu_oce12.gd` à cena do menu atual.
2. Inserir `Fase00HudOverlay12` na cena/controlador da Fase 00.
3. Inserir `Fase00DialogueUi12` no fluxo de diálogo da Fase 00.
4. Instanciar `Fase00ItemMenu12` na Fase 00 para abrir com `Esc`.
5. Revisar `TileMap`/`CollisionPolygon2D`/`CollisionShape2D` das escadas e plataformas.
6. Garantir que o mapeamento de `SpriteFrames` aponte para as novas folhas do protagonista.

## Checklist de colisão Fase 00
- subida e descida de escadas sem travar;
- transição chão → escada;
- transição escada → plataforma;
- plataformas sem “buraco” nas bordas;
- personagem não cai no limbo;
- `F1` exibe colisão para debug.

## Git
### Branch sugerida
`rc2/canonical-visual-rebuild`

### Commit sugerido
`feat(fase00): atualiza menu inicial, HUD, dialogos, itens e protagonista`
