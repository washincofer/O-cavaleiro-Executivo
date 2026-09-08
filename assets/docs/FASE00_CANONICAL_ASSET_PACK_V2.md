# FASE 00 — Pacote Canônico V2

Este pacote consolida os assets enviados pelo usuário para o **Cavaleiro Executivo** e o conjunto inicial de **HUD/UI**.

## Destino no repositório

Copie o conteúdo de `repo_overlay/` para a raiz do repositório.

### Protagonista
`assets/Characters/CavaleiroExecutivo/Runtime/CanonicalV2/`

As folhas do protagonista foram padronizadas para:
- 3 frames por animação
- 320x256 por frame
- folha total 960x256
- PNG com transparência
- orientação preservada da arte enviada

Arquivos:
- Parado.png
- Andando.png
- Ataque.png
- Estocada.png
- Pulo.png
- Caindo.png
- Dano.png
- Morrendo.png
- SubindoEscada.png
- CostasInteracao.png
- SubindoParede.png

### HUD
`assets/UI/Runtime/CanonicalV2/HUD/`
- HP_Protagonista.png
- Cooldown_Habilidade.png
- Info_Salvo_Com_Sucesso.png

### Botões
`assets/UI/Runtime/CanonicalV2/Buttons/`
- Confirmar_Normal.png
- Confirmar_OnClick.png
- Cancelar_Normal.png
- Cancelar_OnClick.png
- Sim.png
- Nao.png
- Iniciar_Normal.png
- Iniciar_OnClick.png
- Opcoes_Normal.png
- Opcoes_OnClick.png
- Continuar.png
- Voltar.png

### Diálogo
`assets/UI/Runtime/CanonicalV2/Dialogue/`
- Balao_Fala_Personagem.png
- Tela_Dialogo_Longo.png

## Importante

Este pack foi montado para **versionar os assets canônicos sem apagar os assets antigos**.
Os arquivos ficam em `CanonicalV2`, permitindo trocar a integração de código com segurança.

A integração definitiva de cada elemento na UI pode ser ajustada depois sem precisar reenviar as imagens.

## Controles canônicos em discussão para a Fase 00

- A / D: movimento
- Space: salto
- W / S: movimento vertical contextual (escada/parede quando aplicável)
- J: ataque
- H: habilidade / estocada
- E: interação / diálogo
- F1: exibir/ocultar colisões

> O pack não altera automaticamente `project.godot` nem controllers. Ele consolida os assets para commit manual seguro.
