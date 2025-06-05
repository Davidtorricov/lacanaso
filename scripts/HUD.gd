extends Control
func _on_boton_diamante_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Combat.tscn")


var fuente_personalizada = preload("res://assets/themes/heme_global.tres")

var mazos = ["Diamantes", "Tréboles", "Picas", "Corazones", "Gangster"]
var mazo_jugable = "Diamantes"

func _ready():
	var contenedor = $MazosHBox

	# Limpiar contenido anterior
	for child in contenedor.get_children():
		child.queue_free()

	for m in mazos:
		# Crear contenedor vertical para imagen + texto
		var carta = VBoxContainer.new()
		carta.set_custom_minimum_size(Vector2(140, 240))
		carta.alignment = BoxContainer.ALIGNMENT_CENTER

		# Imagen (TextureRect)
		var icono = TextureRect.new()
		var nombre_archivo = m.to_lower().replace(" ", "_").replace("é", "e") + ".png"
		icono.texture = load("res://assets/mazos/%s" % nombre_archivo)
		icono.expand = true
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.set_custom_minimum_size(Vector2(160, 220))  # tamaño tipo carta

		# Si el mazo no es jugable → opacar y agregar candado
		if m != mazo_jugable:
			icono.modulate = Color(1, 1, 1, 0.8)  # opacidad al 30%

			var candado = TextureRect.new()
			candado.texture = load("res://assets/icons/candado.png")  # ← verifica que exista
			candado.expand = true
			candado.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			candado.set_anchors_preset(Control.PRESET_FULL_RECT)
			icono.add_child(candado)

		# Nombre del mazo (Label con fuente personalizada)
		var etiqueta = Label.new()
		etiqueta.text = m
		etiqueta.set_custom_minimum_size(Vector2(120, 30))
		etiqueta.horizontal_alignment = 1
		

		if m == mazo_jugable:
			etiqueta.add_theme_color_override("font_color", Color(1, 1, 1))  # blanco
		else:
			etiqueta.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))  # gris

		# Agregar imagen y texto al contenedor
		carta.add_child(icono)
		carta.add_child(etiqueta)

		# Agregar carta al HBox principal
		contenedor.add_child(carta)
