extends Control
class_name MainMenuOCE12

## Menu inicial usando o fundo já existente.
## Trocas visuais:
## - "Novo" => botão/arte "Iniciar"
## - "Continuar" => botão/arte "Continuar"

@onready var btn_new: TextureButton = $CanvasLayer/Buttons/BtnNew
@onready var btn_continue: TextureButton = $CanvasLayer/Buttons/BtnContinue

const BTN_INICIAR_NORMAL := preload("res://assets/UI/Runtime/CorporateUI/ButtonsV2/Iniciar_Normal.png")
const BTN_INICIAR_PRESS := preload("res://assets/UI/Runtime/CorporateUI/ButtonsV2/Iniciar_OnClick.png")
const BTN_CONTINUAR := preload("res://assets/UI/Runtime/CorporateUI/ButtonsV2/Continuar.png")

func _ready() -> void:
	if is_instance_valid(btn_new):
		btn_new.texture_normal = BTN_INICIAR_NORMAL
		btn_new.texture_pressed = BTN_INICIAR_PRESS
		btn_new.texture_hover = BTN_INICIAR_NORMAL
	if is_instance_valid(btn_continue):
		btn_continue.texture_normal = BTN_CONTINUAR
		btn_continue.texture_pressed = BTN_CONTINUAR
		btn_continue.texture_hover = BTN_CONTINUAR
