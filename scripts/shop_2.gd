extends Control

# —————————————————————————————————————————————
#  NODOS de la tienda (Shop2)
# —————————————————————————————————————————————
@onready var boton_comprar_vida    := $PanelPrincipal/ComprarVida
@onready var boton_comprar_escudo  := $PanelPrincipal/ComprarEscudo
@onready var boton_comprar_dano_x2 := $PanelPrincipal/ComprarDanoX2
@onready var boton_salir           := $PanelPrincipal/BotonSalir
@onready var mensaje_label         := $PanelPrincipal/MensajeLabel

func _ready() -> void:
	# Conectar botones a sus callbacks
	boton_comprar_vida.pressed.connect(_comprar_vida)
	boton_comprar_escudo.pressed.connect(_comprar_escudo)
	boton_comprar_dano_x2.pressed.connect(_comprar_dano_x2)
	

	_update_ui()
	mensaje_label.text = ""


# —————————————————————————————————————————————
#  FUNCIONES DE COMPRA (una sola vez POR ESTA VISITA)
#  Usamos metadatos en el nodo para llevar flags locales:
#    "__vida_comprada_shop2", "__escudo_comprado_shop2", "__dano_x2_comprado_shop2"
# —————————————————————————————————————————————
func _comprar_vida() -> void:
	# Chequeo: ¿ya existe el meta "__vida_comprada_shop2"?
	if not has_meta("__vida_comprada_shop2"):
		# Primera vez en esta visita: intentamos comprar vida
		if GameState.comprar_vida():
			mensaje_label.text = "Compraste +20 de vida (3 fichas)."
			set_meta("__vida_comprada_shop2", true)
		else:
			mensaje_label.text = "No tienes suficientes fichas para comprar vida."
	else:
		mensaje_label.text = "Solo puedes comprar vida una vez en esta tienda."
	
	mensaje_label.visible = true
	_update_ui()


func _comprar_escudo() -> void:
	# Chequeo: ¿ya existe el meta "__escudo_comprado_shop2"?
	if not has_meta("__escudo_comprado_shop2"):
		if GameState.comprar_escudo():
			mensaje_label.text = "Compraste la carta de escudo (4 fichas)."
			set_meta("__escudo_comprado_shop2", true)
		else:
			mensaje_label.text = "No tienes suficientes fichas para comprar el escudo."
	else:
		mensaje_label.text = "Solo puedes comprar un escudo en esta tienda."
	
	mensaje_label.visible = true
	_update_ui()


func _comprar_dano_x2() -> void:
	# Chequeo: ¿ya existe el meta "__dano_x2_comprado_shop2"?
	if not has_meta("__dano_x2_comprado_shop2"):
		if GameState.comprar_dano_x2():
			mensaje_label.text = "Compraste la carta de daño ×2 (5 fichas)."
			set_meta("__dano_x2_comprado_shop2", true)
		else:
			mensaje_label.text = "No tienes suficientes fichas para comprar daño ×2."
	else:
		mensaje_label.text = "Solo puedes comprar daño ×2 en esta tienda."
	
	mensaje_label.visible = true
	_update_ui()


# —————————————————————————————————————————————
#  ACTUALIZAR LA UI (según GameState y flags locales)
# —————————————————————————————————————————————
func _update_ui() -> void:
	# Refrescar etiquetas con valores globales
	$PanelPrincipal/FichasLabel.text = str(GameState.fichas_jugador)
	$PanelPrincipal/VidaLabel.text   = str(GameState.vida_jugador)

	# Deshabilitar botones de compra solo si ya existe el flag local
	boton_comprar_escudo.disabled   = has_meta("__escudo_comprado_shop2")
	boton_comprar_dano_x2.disabled  = has_meta("__dano_x2_comprado_shop2")
	boton_comprar_vida.disabled     = has_meta("__vida_comprada_shop2")


# —————————————————————————————————————————————
#  BOTÓN “SALIR”: vuelve a combate
# —————————————————————————————————————————————
func _on_boton_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/finalcombat.tscn")
