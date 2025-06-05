extends Control

# Este código se coloca en la escena de menú principal (cuando inicias una nueva partida)

func _on_boton_play_pressed() -> void:
	# Restablecer los valores globales en GameState
	GameState.vida_jugador = 100  # Establecer vida inicial
	GameState.fichas_jugador = 2  # Establecer fichas iniciales

	# Cargar la escena del juego
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_boton_instrucciones_pressed() -> void:
	# Mostrar el popup de instrucciones (cuando lo creemos)
	$PopupInstrucciones.popup_centered()

func _on_boton_opciones_pressed() -> void:
	# Mostrar un popup de opciones (a crear más adelante)
	$PopupOpciones.popup_centered()

func _on_boton_salir_pressed() -> void:
	# Salir del juego
	get_tree().quit()

func _on_button_pressed() -> void:
	$PopupOpciones.popup_centered()

func _on_button_2_pressed() -> void:
	$PopupOpciones.popup_centered()

func _on_buttonsalirinst_pressed() -> void:
	$PopupInstrucciones.hide()

func _on_buttonsaliropc_pressed() -> void:
	$PopupOpciones.hide()

func _on_slider_volumen_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value / 100.0))

func _on_check_musica_toggled(toggled_on: bool) -> void:
	var index = AudioServer.get_bus_index("Música")
	AudioServer.set_bus_mute(index, not toggled_on)
