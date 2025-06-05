extends CanvasLayer  # Usar CanvasLayer como base

@onready var mensaje_final := $mensajefi  # Nodo con el mensaje de victoria
@onready var boton_menu   := $BotonMe     # Nodo botón "Menú"
@onready var boton_salir  := $BotonSali   # Nodo botón "Salir"

func _ready() -> void:
	# Verificar que los botones y mensaje_final estén presentes en la escena
	if mensaje_final:
		mensaje_final.text = "¡Felicidades! Has derrotado a Don Rico."  # Mensaje personalizado
		mensaje_final.visible = true  # Hacer visible el mensaje
	else:
		print("El nodo mensaje_final no se encontró en la escena.")
	
	if boton_menu and boton_salir:
		# Configurar los botones
		boton_menu.disabled = false
		boton_salir.disabled = false
		
		# Conectar los botones
		boton_menu.pressed.connect(_on_boton_menu_pressed)
		boton_salir.pressed.connect(_on_boton_salir_pressed)
	else:
		print("Los botones no se encontraron en la escena.")

	# Animar victoria
	_animar_victoria()

# Animación de victoria
func _animar_victoria() -> void:
	# Asegurarse de que 'mensaje_final' no sea null
	if not mensaje_final:
		print("mensaje_final no encontrado.")
		return


# Función para el botón "Menú"
func _on_boton_menu_pressed() -> void:
	print("Ir al menú principal")
	get_tree().change_scene_to_file("res://scenes/Inicio.tscn")

# Función para el botón "Salir"
func _on_boton_salir_pressed() -> void:
	print("Salir del juego")
	get_tree().quit()  # Salir del juego
