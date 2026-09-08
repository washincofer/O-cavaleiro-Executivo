extends Node

## Overlay visual da Fase 02.
## Fica acima dos retangulos de background do primeiro prototipo (-20)
## e abaixo das plataformas/atores (0+), garantindo leitura real do mapa.

const FASE02 := "res://scenes/playtest/platform_fase02_tecnologia_12.tscn"
var handled_scene_id := 0

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != FASE02:
		return
	var sid := scene.get_instance_id()
	if sid == handled_scene_id:
		return
	handled_scene_id = sid
	call_deferred("_build_overlay", scene)

func _build_overlay(scene: Node) -> void:
	if not is_instance_valid(scene) or scene.get_node_or_null("TechnologyForegroundMap") != null:
		return
	var root := Node2D.new()
	root.name = "TechnologyForegroundMap"
	root.z_index = -15
	scene.add_child(root)

	var sectors := [
		[0.0, 980.0, Color("101b2c"), "SERVICE DESK"],
		[980.0, 1960.0, Color("0c2730"), "DATACENTER"],
		[1960.0, 2940.0, Color("13223a"), "REDES & BACKUP"],
		[2940.0, 4140.0, Color("1d2138"), "SEGURANCA & GOVERNANCA"],
		[4140.0, 5200.0, Color("291d36"), "CONSELHO DE GOVERNANCA"],
	]

	for data in sectors:
		var x0 := float(data[0])
		var x1 := float(data[1])
		var panel := ColorRect.new()
		panel.position = Vector2(x0, 0)
		panel.size = Vector2(x1 - x0, 268)
		panel.color = data[2]
		panel.z_index = -15
		root.add_child(panel)

		var title := Label.new()
		title.text = String(data[3])
		title.position = Vector2(x0 + 22, 40)
		title.add_theme_font_size_override("font_size", 9)
		title.add_theme_color_override("font_color", Color("8ee8ff"))
		title.z_index = -12
		root.add_child(title)

		for x in range(int(x0 + 74), int(x1 - 30), 144):
			var rack := ColorRect.new()
			rack.position = Vector2(x, 82)
			rack.size = Vector2(52, 154)
			rack.color = Color("30465b")
			rack.z_index = -14
			root.add_child(rack)
			var glass := ColorRect.new()
			glass.position = Vector2(x + 5, 88)
			glass.size = Vector2(42, 142)
			glass.color = Color("16293a")
			glass.z_index = -13
			root.add_child(glass)
			for y in range(100, 218, 18):
				var led := ColorRect.new()
				led.position = Vector2(x + 10, y)
				led.size = Vector2(32, 3)
				led.color = Color("57d7b2")
				led.z_index = -12
				root.add_child(led)

	var floor_strip := ColorRect.new()
	floor_strip.position = Vector2(0, 256)
	floor_strip.size = Vector2(5200, 28)
	floor_strip.color = Color("293e52")
	floor_strip.z_index = -11
	root.add_child(floor_strip)
