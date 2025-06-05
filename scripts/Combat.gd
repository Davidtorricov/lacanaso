extends Control

# ——————————————————————————————————————
#  NODOS (asegúrate de que existan en tu escena):
# ——————————————————————————————————————
@onready var cont_jugador    := $UI/ZonaJugador/CartasJugador
@onready var cont_enemigo    := $UI/ZonaEnemigo/CartasEnemigo
@onready var boton_pedir     := $UI/BotonesJuego/BotonPedir
@onready var boton_plantarse := $UI/BotonesJuego/BotonPlantarse
@onready var mensaje_central := $UI/MensajeCentral

@onready var vida_label_j    := $UI/InfoJugador/Overlay/VidaLabel
@onready var fichas_label    := $UI/InfoJugador/Overlay/FichasLabel
@onready var vida_label_e    := $UI/InfoEnemigo/Overlay/VidaLabel

# ——————————————————————————————————————
#  ESTADO DEL JUEGO (usando GameState para vida y fichas)
# ——————————————————————————————————————
var vida_enemigo   : int = 80

var mazo_jugador  : Array = []
var mazo_enemigo  : Array = []
var mano_jug      : Array = []
var mano_ene      : Array = []

func _ready() -> void:
	_inicializar_mazos()
	_reiniciar_ronda()
	
	# Conectar botones
	boton_pedir.pressed.connect(_on_pedir)
	boton_plantarse.pressed.connect(_on_plantarse)
	
	# Cargar vida y fichas desde el singleton global GameState
	_update_ui()

# ——————————————————————————————————————
#  INICIALIZACIÓN
# ——————————————————————————————————————
func _inicializar_mazos() -> void:
	for i in range(1, 14):
		var valor = i
		if i == 1:
			valor = 11  # As puede ser 11 (ajustaremos en el cálculo)
		elif i >= 11:
			valor = 10  # J, Q, K valen 10
		mazo_jugador.append({
			"valor": valor,
			"imagen": "res://assets/cards/diamonds/diamond_" + str(i) + ".png"
		})
		mazo_enemigo.append({
			"valor": valor,
			"imagen": "res://assets/cards/spades/spade_" + str(i) + ".png"
		})

	mazo_jugador.shuffle()
	mazo_enemigo.shuffle()

func _reiniciar_ronda() -> void:
	# Limpia manos y contenedores
	mano_jug.clear()
	mano_ene.clear()
	for c in cont_jugador.get_children(): c.queue_free()
	for c in cont_enemigo.get_children(): c.queue_free()
	# Reactivar botones
	boton_pedir.disabled = false
	boton_plantarse.disabled = false
	mensaje_central.visible = false
	# Reparto inicial
	_dar_carta(true)
	_dar_carta(true)
	_dar_carta(false)
	_dar_carta(false)
	_update_ui()

# ——————————————————————————————————————
#  REPARTO DE CARTAS
# ——————————————————————————————————————
func _dar_carta(es_jug: bool) -> void:
	var mazo = mazo_jugador if es_jug else mazo_enemigo
	if mazo.size() == 0:
		if es_jug:
			mensaje_central.text = "¡La baraja está vacía!"
			mensaje_central.visible = true
		return
	
	var carta = mazo.pop_front()
	mazo.append(carta)
	if es_jug:
		mano_jug.append(carta)
		_mostrar_carta(carta, cont_jugador)
		
		if _total(mano_jug) > 21:
			# Le restas vida al jugador (puedes ajustar el daño)
			GameState.vida_jugador -= 20  # Usamos GameState para vida global
			
			# Mostrar mensaje y terminar ronda o reiniciar
			_terminar("¡Te pasaste! Perdiste 20 de vida.")
			
			# Actualizar UI para reflejar la nueva vida
			_update_ui()
	else:
		mano_ene.append(carta)
		_mostrar_carta(carta, cont_enemigo)

# ——————————————————————————————————————
#  MOSTRAR UNA CARTA EN PANTALLA
# ——————————————————————————————————————
func _mostrar_carta(carta: Dictionary, cont: Control) -> void:
	var img = TextureRect.new()
	img.texture = load(carta.imagen)
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.set_custom_minimum_size(Vector2(100, 150))
	cont.add_child(img)

# ——————————————————————————————————————
#  CALCULAR EL TOTAL DE LA MANO
# ——————————————————————————————————————
func _total(mano: Array) -> int:
	var s := 0
	for c in mano:
		s += c.valor
	return s

# ——————————————————————————————————————
#  BOTONES
# ——————————————————————————————————————
func _on_pedir() -> void:
	_dar_carta(true)
	_update_ui()

func _on_plantarse() -> void:
	boton_pedir.disabled = true
	boton_plantarse.disabled = true
	mensaje_central.text = "Turno enemigo..."
	mensaje_central.visible = true
	_turno_enemigo()

# ——————————————————————————————————————
#  IA ENEMIGA (recursiva con await)
# ——————————————————————————————————————
func _turno_enemigo() -> void:
	if _total(mano_ene) < 15:
		_dar_carta(false)
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(self._turno_enemigo)
	else:
		_resolver_combate()

# ——————————————————————————————————————
#  RESOLUCIÓN & DAÑO
# ——————————————————————————————————————
func _resolver_combate() -> void:
	var tj = _total(mano_jug)  # Total de cartas del jugador
	var te = _total(mano_ene)  # Total de cartas del enemigo

	# 1) Verificar si el jugador se pasa de 21
	if tj > 21:
		GameState.vida_jugador = max(GameState.vida_jugador - 20, 0)
		_terminar("¡Te pasaste! Perdiste 20 de vida.")
		return

	# 2) Verificar si el enemigo se pasa de 21
	if te > 21:
		vida_enemigo = max(vida_enemigo - 20, 0)
		_premiar("¡Ganaste! Enemigo se pasó. +1 ficha")
		return

	# 3) Comparar totales si nadie se pasó
	if tj > te:
		var d =  + 4 * (tj - te)
		vida_enemigo = max(vida_enemigo - d, 0)
		_premiar("¡Ganaste! Daño: %d" % d)
		return
	elif tj == te:
		_terminar("¡Empate!")
		return
	else:
		var d =  + 4 * (te - tj)
		GameState.vida_jugador = max(GameState.vida_jugador - d, 0)
		_terminar("¡Perdiste! Daño: %d" % d)


# ——————————————————————————————————————
#  FIN DE LA RONDA
# ——————————————————————————————————————
func _fin_ronda():
	if GameState.vida_jugador <= 0:
		print("Jugador perdió, yendo a menú principal")
		get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn")
	elif vida_enemigo <= 0:
		print("Enemigo derrotado, esperando 5 segundos para tienda")
		var timer = get_tree().create_timer(5.0)
		timer.timeout.connect(Callable(self, "_ir_tienda"))
		get_tree().change_scene_to_file("res://scenes/Shop.tscn")
	else:
		print("Nadie perdió, yendo directo a tienda")
		get_tree().change_scene_to_file("res://scenes/Shop.tscn")

func _ir_tienda():
	print("Cambiando a tienda")
	get_tree().change_scene_to_file("res://scenes/Shop.tscn")

# ——————————————————————————————————————
#  PREMIAR - AÑADE UNA FICHA AL JUGADOR
# ——————————————————————————————————————
func _premiar(texto: String) -> void:
	# Usamos GameState para gestionar las fichas globales
	GameState.fichas_jugador += 1
	_terminar(texto )

# ——————————————————————————————————————
#  TERMINAR - MUESTRA MENSAJE Y BLOQUEA BOTONES
# ——————————————————————————————————————
func _terminar(texto: String) -> void:
	mensaje_central.text = texto
	mensaje_central.visible = true
	boton_pedir.disabled = true
	boton_plantarse.disabled = true
	_update_ui()
	
	# Esperar 2 segundos para que el jugador lea el mensaje
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(Callable(self, "_terminar_accion"))

func _terminar_accion():
	_update_ui()
	
	# Verificar si el jugador perdió
	if GameState.vida_jugador <= 0:
		mensaje_central.text = "¡Perdiste la partida! 
		saliendo al menu principal"
		get_tree().create_timer(2.0).timeout.connect(Callable(self, "_ir_menu_principal"))
	elif vida_enemigo <= 0:
		mensaje_central.text = "¡Ganaste la ronda! 
		entrando a la tienda"
		get_tree().create_timer(2.0).timeout.connect(Callable(self, "_ir_tienda"))
	else:
		_reiniciar_ronda()

func _ir_menu_principal():
	get_tree().change_scene_to_file("res://scenes/Inicio.tscn")


# ——————————————————————————————————————
#  ACTUALIZAR UI
# ——————————————————————————————————————
func _update_ui() -> void:
	vida_label_j.text = str(GameState.vida_jugador)
	fichas_label.text = str(GameState.fichas_jugador)
	vida_label_e.text = str(vida_enemigo)
