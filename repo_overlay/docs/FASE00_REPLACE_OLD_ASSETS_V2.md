# CE FASE 00 — Replace Old Assets V2

Este pack foi feito para **substituir diretamente** os assets antigos já usados pelo código atual.

## O que sobrescreve

### Cavaleiro Executivo
Destino:
`assets/Characters/CavaleiroExecutivo/Runtime/`

Arquivos sobrescritos:
- `Parado.png`
- `Andando.png`
- `Ataque.png`
- `Estocada.png`
- `Pulo.png`
- `Caindo.png`

As novas artes foram reformatadas para os recortes/dimensões que o `platform_actor_12.gd`
já espera hoje. Isso permite substituir as imagens sem precisar alterar o mapeamento antigo
somente para esses seis estados.

Arquivos novos adicionados para uso posterior:
- `Dano.png`
- `Morrendo.png`
- `SubindoEscada.png`
- `CostasInteracao.png`
- `SubindoParede.png`

### Corporate UI
Destino:
`assets/UI/Runtime/CorporateUI/`

Sobrescreve diretamente:
- `hp_frame_protagonist.png`
- `cooldown_frame.png`
- `dialogue_panel.png`

## Botões enviados

O sistema atual de botões (`CorporateUI12.style_button`) é desenhado em código com
`StyleBoxFlat`; portanto não existe hoje um PNG antigo equivalente para sobrescrever.

Para não quebrar menus existentes, os botões enviados foram colocados em:
`assets/UI/Runtime/CorporateUI/ButtonsV2/`

Isso inclui Confirmar, Cancelar, Sim/Não, Iniciar, Opções, Continuar, Voltar,
toast de salvamento e balão de fala. A ligação desses botões ao código pode ser feita
na próxima etapa, sem destruir a UI atual.

## Importante sobre o HP do protagonista

Este pack usa **exatamente a arte fornecida pelo usuário** no arquivo
`hp_frame_protagonist.png`, sem corrigir textos ou composição da imagem.

## Godot

Não copie arquivos `.import` antigos do ZIP. Ao abrir o projeto, o Godot detecta os PNGs
modificados e atualiza os imports automaticamente.

## Branch recomendada

`rc2/canonical-visual-rebuild`
