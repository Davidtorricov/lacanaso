extends Control

# —————————————————————————————————————————————
#  NODOS
# —————————————————————————————————————————————
@onready var cont_jugador    := $UI/ZonaJugador/CartasJugador
@onready var cont_enemigo    := $UI/ZonaEnemigo/CartasEnemigo
@onready var boton_pedir     := $UI/BotonesJuego/BotonPedir
@onready var boton_plantarse := $UI/BotonesJuego/BotonPlantarse
@onready var mensaje_central := $UI/MensajeCentral

@onready var vida_label_j    := $UI/InfoJugador/Overlay/VidaLabel
@onready var fichas_label    := $UI/InfoJugador/Overlay/FichasLabel
@onready var vida_label_e    := $UI/InfoEnemigo/Overlay/VidaLabel

@onready var boton_escudo    := $UI/BotonEscudo
@onready var boton_dano_x2   := $UI/BotonDanoX2

# —————————————————————————————————————————————
#  ESTADO DEL JUEGO
# —————————————————————————————————————————————
var vida_jugador   : int = GameState.vida_jugador
var fichas_jugador : int = GameState.fichas_jugador
var vida_enemigo   : int = 100

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
	boton_escudo.pressed.connect(_on_activarescudo_pressed)
	boton_dano_x2.pressed.connect(_on_activarx_2_pressed)

	# Habilitar/Deshabilitar botones de escudo y daño x2 según las compras
	boton_escudo.disabled = (GameState.reservas_escudo <= 0)
	boton_dano_x2.disabled = (GameState.reservas_dano_x2 <= 0)

	_update_ui()

# —————————————————————————————————————————————
#  INICIALIZACIÓN DE MAZOS
# —————————————————————————————————————————————
func _inicializar_mazos() -> void:
	for i in range(1, 14):
		var valor = i
		if i == 1:
			valor = 11  # As puede valer 11
		elif i >= 11:
			valor = 10  # J, Q, K valen 10
		mazo_jugador.append({
			"valor": valor,
			"imagen": "res://assets/cards/diamonds/diamond_" + str(i) + ".png"
		})
		mazo_enemigo.append({
			"valor": valor,
			"imagen": "res://assets/cards/hearts/heart_" + str(i) + ".png"
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

# —————————————————————————————————————————————
#  REPARTO DE CARTAS
# —————————————————————————————————————————————
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
		# Si el jugador se pasa inmediatamente de 21, pierde 20 de vida
		if _total(mano_jug) > 21:
			GameState.vida_jugador -= 20
			_terminar("¡Te pasaste! Perdiste 20 de vida.")
			_update_ui()
	else:
		mano_ene.append(carta)
		_mostrar_carta(carta, cont_enemigo)

func _mostrar_carta(carta: Dictionary, cont: Control) -> void:
	var img = TextureRect.new()
	img.texture = load(carta.imagen)
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.set_custom_minimum_size(Vector2(100, 150))
	cont.add_child(img)

func _total(mano: Array) -> int:
	var s := 0
	for c in mano:
		s += c.valor
	return s

# —————————————————————————————————————————————
#  MANEJO DE BOTONES
# —————————————————————————————————————————————
func _on_pedir() -> void:
	_dar_carta(true)
	_update_ui()

func _on_plantarse() -> void:
	boton_pedir.disabled = true
	boton_plantarse.disabled = true
	mensaje_central.text = "Turno enemigo..."
	mensaje_central.visible = true
	_turno_enemigo()

# —————————————————————————————————————————————
#  IA ENEMIGA
# —————————————————————————————————————————————
func _turno_enemigo() -> void:
	if _total(mano_ene) < 17:
		_dar_carta(false)
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(self._turno_enemigo)
	else:
		_resolver_combate()

# —————————————————————————————————————————————
#  RESOLUCIÓN & DAÑO
# —————————————————————————————————————————————
func _resolver_combate() -> void:
	var tj = _total(mano_jug)  # Total de cartas del jugador
	var te = _total(mano_ene)  # Total de cartas del enemigo
	var dano = 0  # Definimos la variable dano una vez aquí

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

	# 3) Si el jugador obtuvo Blackjack (exactamente 21)
	if tj == 21:
		dano = 21
		# Si el daño x2 está activado, duplicamos ese 21
		if GameState.dano_x2_activo:
			dano = GameState.aplicar_dano_x2(dano)
		vida_enemigo = max(vida_enemigo - dano, 0)
		_premiar("¡Ganaste con Blackjack! Daño: %d" % dano)
		return

	# 4) Si el enemigo obtuvo Blackjack (exactamente 21)
	if te == 21:
		dano = 21
		# Si el daño x2 está activado, duplicamos ese 21
		if GameState.dano_x2_activo:
			dano = GameState.aplicar_dano_x2(dano)
		# Antes de descontar, aplicamos escudo (si lo tuviera)
		if GameState.tiene_escudo:
			dano = GameState.aplicar_escudo(dano)
		GameState.vida_jugador = max(GameState.vida_jugador - dano, 0)
		_terminar("¡Perdiste contra un Blackjack! Daño: %d" % dano)
		return

	# 5) Si ninguno hizo Blackjack ni se pasó, comparamos totales normales
	if tj > te:
		# Jugador gana por diferencia
		dano =  + 5 * (tj - te)  # daño base = diferencia de puntos
		# Aplicar daño x2 si está activado
		if GameState.dano_x2_activo:
			dano = GameState.aplicar_dano_x2(dano)
		vida_enemigo = max(vida_enemigo - dano, 0)
		_premiar("¡Ganaste! Daño: %d" % dano)
		return

	if tj == te:
		# Empate, no hay daño
		_terminar("¡Empate!")
		return

	# Caso: el enemigo gana por diferencia
	if te > tj:
		dano = 5 * (te - tj)  # daño base = diferencia de puntos
		# Aplicar daño x2 si está activado
		if GameState.dano_x2_activo:
			dano = GameState.aplicar_dano_x2(dano)
		# Ahora aplicamos escudo (si el jugador lo tuviera)
		if GameState.tiene_escudo:
			dano = GameState.aplicar_escudo(dano)
		GameState.vida_jugador = max(GameState.vida_jugador - dano, 0)
		_terminar("¡Perdiste! Daño: %d" % dano)

# —————————————————————————————————————————————
#  FUNCIONES DE ESCUDO Y DAÑO X2 (se activan al presionar botones)
# —————————————————————————————————————————————
func _on_activarescudo_pressed() -> void:
	if GameState.reservas_escudo > 0:
		GameState.reservas_escudo -= 1
		GameState.tiene_escudo = true
		boton_escudo.disabled = true
		mensaje_central.text = "Escudo activado para la próxima ronda."
		mensaje_central.visible = true
	else:
		mensaje_central.text = "No tienes escudos disponibles."
		mensaje_central.visible = true

func _on_activarx_2_pressed() -> void:
	if GameState.reservas_dano_x2 > 0:
		GameState.reservas_dano_x2 -= 1
		GameState.dano_x2_activo = true
		boton_dano_x2.disabled = true
		mensaje_central.text = "Daño x2 activado para la próxima ronda."
		mensaje_central.visible = true
	else:
		mensaje_central.text = "No has comprado daño x2 o ya está activado."
		mensaje_central.visible = true

# —————————————————————————————————————————————
#  ACTUALIZAR UI
# —————————————————————————————————————————————
func _update_ui() -> void:
	vida_label_j.text = str(GameState.vida_jugador)
	fichas_label.text = str(GameState.fichas_jugador)
	vida_label_e.text = str(vida_enemigo)

func _fin_ronda():
	if GameState.vida_jugador <= 0:
		get_tree().change_scene_to_file("res://scenes/Inicio.tscn")
	elif vida_enemigo <= 0:
		var timer = get_tree().create_timer(5.0)
		timer.timeout.connect(Callable(self, "_ir_tienda"))
		get_tree().change_scene_to_file("res://scenes/Shop2.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Shop2.tscn")

func _ir_tienda():
	get_tree().change_scene_to_file("res://scenes/Shop2.tscn")

func _premiar(texto: String) -> void:
	GameState.fichas_jugador += 1
	_terminar(texto + " +1 ficha")

func _terminar(texto: String) -> void:
	mensaje_central.text = texto
	mensaje_central.visible = true
	boton_pedir.disabled = true
	boton_plantarse.disabled = true
	_update_ui()

	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(Callable(self, "_terminar_accion"))

func _terminar_accion():
	_update_ui()
	if GameState.vida_jugador <= 0:
		mensaje_central.text = "¡Perdiste la partida!"
		get_tree().create_timer(2.0).timeout.connect(Callable(self, "_ir_menu_principal"))
	elif vida_enemigo <= 0:
		mensaje_central.text = "¡Ganaste la partida!"
		get_tree().create_timer(5.0).timeout.connect(Callable(self, "_ir_tienda"))
	else:
		_reiniciar_ronda()

func _ir_menu_principal():
	get_tree().change_scene_to_file("res://scenes/Inicio.tscn")
