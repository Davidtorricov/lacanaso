extends Control

@onready var cont_jugador    := $UI/ZonaJugador/CartasJugador
@onready var cont_enemigo    := $UI/ZonaEnemigo/CartasEnemigo
@onready var boton_pedir     := $UI/BotonesJuego/BotonPedir
@onready var boton_plantarse := $UI/BotonesJuego/BotonPlantarse
@onready var mensaje_central := $UI/MensajeCentral

@onready var vida_label_j    := $UI/InfoJugador/Overlay/VidaLabel
@onready var fichas_label    := $UI/InfoJugador/Overlay/FichasLabel
@onready var vida_label_e    := $UI/InfoEnemigo/Overlay/VidaLabel

@onready var boton_escudo   := $UI/BotonEscudo
@onready var boton_dano_x2  := $UI/BotonDanoX2

# ESTADO DEL JUEGO Y DEL BOSS
var vida_enemigo   : int = 100     # HP actual de Don Rico
var jefe_se_curo   : bool = false      # Marca si ya usó la auto‐cura
var turnos_pasados : int = 0           # Contador de “turnos completos” de la IA

var mazo_jugador   : Array = []
var mazo_enemigo   : Array = []
var mano_jug       : Array = []
var mano_ene       : Array = []

func _ready() -> void:
	_reiniciar_ronda()

	boton_pedir.pressed.connect(_on_pedir)
	boton_plantarse.pressed.connect(_on_plantarse)
	boton_escudo.pressed.connect(_on_activarescudo_pressed)
	boton_dano_x2.pressed.connect(_on_activarx_2_pressed)

	boton_escudo.disabled  = (GameState.reservas_escudo <= 0)
	boton_dano_x2.disabled = (GameState.reservas_dano_x2 <= 0)

	_update_ui()
	mensaje_central.visible = false


# INICIALIZACIÓN
func _inicializar_mazos() -> void:
	mazo_jugador.clear()
	mazo_enemigo.clear()
	for i in range(1, 14):
		var valor = i
		if i == 1:
			valor = 11
		elif i >= 11:
			valor = 10

		mazo_jugador.append({
			"valor": valor,
			"imagen": "res://assets/cards/diamonds/diamond_%d.png" % i
		})
		mazo_enemigo.append({
			"valor": valor,
			"imagen": "res://assets/cards/spades/spade_%d.png" % i
		})

	mazo_jugador.shuffle()
	mazo_enemigo.shuffle()


# REINICIA RONDA: MAZOS FRESCOS, MANOS VACÍAS, REPARTO INICIAL
func _reiniciar_ronda() -> void:
	_inicializar_mazos()

	mano_jug.clear()
	mano_ene.clear()
	for c in cont_jugador.get_children():
		c.queue_free()
	for c in cont_enemigo.get_children():
		c.queue_free()

	boton_pedir.disabled    = false
	boton_plantarse.disabled = false
	mensaje_central.visible = false

	_dar_carta(true)
	_dar_carta(true)
	_dar_carta(false)
	_dar_carta(false)

	_update_ui()


# REPARTO DE CARTAS (SIN REINSERCION—cada carta se usa solo una vez)
func _dar_carta(es_jug: bool) -> void:
	var mazo = mazo_jugador if es_jug else mazo_enemigo

	if mazo.size() == 0:
		if es_jug:
			mensaje_central.text = "¡La baraja está vacía!"
			mensaje_central.visible = true
		return

	var carta = mazo.pop_front()
	if es_jug:
		mano_jug.append(carta)
		_mostrar_carta(carta, cont_jugador)

		if _total(mano_jug) > 21:
			# Bloquear botones al pasarse
			boton_pedir.disabled = true
			boton_plantarse.disabled = true

			GameState.vida_jugador = max(GameState.vida_jugador - 20, 0)
			mensaje_central.text = "¡Te pasaste! Perdiste 20 de vida."
			mensaje_central.visible = true
			_update_ui()
			await get_tree().create_timer(2.0).timeout
			if GameState.vida_jugador <= 0:
				mensaje_central.text = "¡Perdiste la partida!"
				await get_tree().create_timer(2.0).timeout
				_ir_menu_principal()
			else:
				_reiniciar_ronda()
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
	var suma := 0
	for c in mano:
		suma += c.valor
	return suma


# BOTONES
func _on_pedir() -> void:
	_dar_carta(true)
	_update_ui()


func _on_plantarse() -> void:
	boton_pedir.disabled = true
	boton_plantarse.disabled = true
	mensaje_central.text = "Turno enemigo..."
	mensaje_central.visible = true
	await get_tree().create_timer(1.0).timeout  # Retardo para leer mensaje
	_turno_enemigo()


# IA ENEMIGA (Don Rico) – LÓGICA “INTELIGENTE”:
# 1) Si mano < 17, pide
# 2) Si mano >= 20, se planta
# 3) Si mano 17–19:
#  • Si mano del jugador > IA → arriesga (“hit”) hasta alcanzar 18
#  • Si mano del jugador ≤ IA → se planta
# 4) Cada 3 turnos pasados la IA evalúa si cambiar las cartas (si le conviene)
# Lógica del turno de Don Rico (la IA)
# Lógica del turno de Don Rico (la IA)
func _turno_enemigo() -> void:
	var te = _total(mano_ene)  # Total de cartas del enemigo
	var tj = _total(mano_jug)  # Total de cartas del jugador

	# 1) La IA no pide siempre si tiene menos de 17, sino que evalúa la situación:
	if te < 17:
		# Si la mano del jugador es muy fuerte (por ejemplo, 18 o más), la IA no arriesga
		if tj >= 18 and randf() < 0.3:  # Un 30% de probabilidad de pedir
			_dar_carta(false)
			await get_tree().create_timer(0.7).timeout
			_turno_enemigo()
			return
		# Si la mano del jugador es débil, la IA puede decidir pedir más cartas
		else:
			_dar_carta(false)
			await get_tree().create_timer(0.7).timeout
			_turno_enemigo()
			return

	# 2) Si la IA tiene 21, se planta inmediatamente (Blackjack)
	if te == 21:
		turnos_pasados += 1
		if turnos_pasados >= 3:
			_eval_intercambio()  # Se evalúa si es necesario intercambiar las cartas
			turnos_pasados = 0
		_resolver_combate()
		return

	# 3) Si la IA tiene 17 a 19, depende de la mano del jugador:
	if te >= 17 and te < 20:
		# Si el jugador tiene una mano más fuerte que la IA, la IA puede arriesgarse
		if tj > te:
			# Si el jugador tiene una mano mucho mayor, la IA arriesga para intentar mejorar
			if te < 18 and randf() < 0.7:  # 70% de chance de pedir
				_dar_carta(false)
				await get_tree().create_timer(0.7).timeout
				_turno_enemigo()
				return
		# Si el jugador tiene una mano igual o menor que la IA, la IA se planta
		turnos_pasados += 1
		if turnos_pasados >= 3:
			_eval_intercambio()  # Evaluar si cambiar de mazo
			turnos_pasados = 0
		_resolver_combate()
		return
	
	# 4) Si la IA tiene entre 17 y 19 y el jugador tiene una mano baja, la IA se planta
	if te >= 17 and te < 20 and tj <= 16:
		turnos_pasados += 1
		if turnos_pasados >= 3:
			_eval_intercambio()  # Evaluar si cambiar de mazo
			turnos_pasados = 0
		_resolver_combate()
		return

	# 5) Si la IA tiene 20 o más, se planta siempre
	if te >= 20:
		turnos_pasados += 1
		if turnos_pasados >= 3:
			_eval_intercambio()  # Evaluar si cambiar de mazo
			turnos_pasados = 0
		_resolver_combate()
		return

	# La IA se planta si no puede mejorar mucho la mano
	turnos_pasados += 1
	if turnos_pasados >= 3:
		_eval_intercambio()  # Evaluar si cambiar de mazo
		turnos_pasados = 0
	_resolver_combate()


# Cambiar las cartas entre la IA y el jugador si es necesario
func _eval_intercambio() -> void:
	var tj = _total(mano_jug)  # Total de cartas del jugador
	var te = _total(mano_ene)  # Total de cartas del enemigo

	# Si la mano del jugador es mayor que la del enemigo y el jugador no se pasó de 21
	if tj > te and tj <= 21:
		mensaje_central.text = "¡Don Rico activa truco: cambiará cartas!"
		mensaje_central.visible = true
		await get_tree().create_timer(1.5).timeout
		_intercambiar_manos()

# Intercambio de manos
func _intercambiar_manos() -> void:
	var temp_jug = mano_jug.duplicate()
	var temp_ene = mano_ene.duplicate()

	mano_jug.clear()
	mano_ene.clear()
	for c in cont_jugador.get_children():
		c.queue_free()
	for c in cont_enemigo.get_children():
		c.queue_free()

	mano_jug = temp_ene.duplicate()
	mano_ene = temp_jug.duplicate()

	for carta in mano_jug:
		_mostrar_carta(carta, cont_jugador)
	for carta in mano_ene:
		_mostrar_carta(carta, cont_enemigo)

	mensaje_central.text = "¡Intercambio de manos completado!"
	mensaje_central.visible = true
	await get_tree().create_timer(2.0).timeout
	mensaje_central.visible = false



# RESOLUCIÓN & DAÑO (incluye cura única al 50% si baja a 0)
func _resolver_combate() -> void:
	var tj = _total(mano_jug)
	var te = _total(mano_ene)

	# 1) Don Rico se pasa:
	if te > 21:
		vida_enemigo = max(vida_enemigo - 20, 0)
		if vida_enemigo <= 0 and not jefe_se_curo:
			vida_enemigo = 100
			jefe_se_curo = true
			mensaje_central.text = "¡Don Rico resucita con fuerza!"
			mensaje_central.visible = true
			await get_tree().create_timer(2.0).timeout
			_reiniciar_ronda()
		else:
			_premiar("¡Ganaste! Enemigo se pasó. +1 ficha")
		return

	# 2) Escudo del jugador (solo afecta daño a salud)
	var escudo_activo = GameState.tiene_escudo

	# 3) Jugador se pasa:
	if tj > 21:
		GameState.vida_jugador = max(GameState.vida_jugador - 20, 0)
		_terminar("¡Te pasaste! Perdiste 20 de vida.")
		return

	# 4) Blackjack del jugador
	if tj == 21:
		var dano_jugador: int = 21
		if GameState.dano_x2_activo:
			dano_jugador = GameState.aplicar_dano_x2(dano_jugador)
		vida_enemigo = max(vida_enemigo - dano_jugador, 0)
		if vida_enemigo <= 0 and not jefe_se_curo:
			vida_enemigo = 1
			jefe_se_curo = true
			mensaje_central.text = "¡Don Rico resucita con fuerza!"
			mensaje_central.visible = true
			await get_tree().create_timer(2.0).timeout
			_reiniciar_ronda()
		else:
			_premiar("¡Ganaste con Blackjack! Daño: %d" % dano_jugador)
		return

	# 5) Blackjack de Don Rico
	if te == 21:
		var dano_boss: int = 21
		if escudo_activo:
			dano_boss = GameState.aplicar_escudo(dano_boss)
		GameState.vida_jugador = max(GameState.vida_jugador - dano_boss, 0)
		GameState.tiene_escudo = false
		_terminar("¡Perdiste contra un Blackjack! Daño: %d" % dano_boss)
		return

	# 6) Comparar totales normales
	if tj > te:
		var d: int = 6 * (tj - te)
		if GameState.dano_x2_activo:
			d = GameState.aplicar_dano_x2(d)
		vida_enemigo = max(vida_enemigo - d, 0)
		if vida_enemigo <= 0 and not jefe_se_curo:
			vida_enemigo = 100
			jefe_se_curo = true
			mensaje_central.text = "¡Don Rico resucita con fuerza!"
			mensaje_central.visible = true
			await get_tree().create_timer(2.0).timeout
			_reiniciar_ronda()
		else:
			_premiar("¡Ganaste! Daño: %d" % d)
		return

	if tj == te:
		_terminar("¡Empate!")
		return

	# 7) Don Rico gana por diferencia
	if te > tj:
		var d2: int = 6 * (te - tj)
		if escudo_activo:
			d2 = GameState.aplicar_escudo(d2)
		GameState.vida_jugador = max(GameState.vida_jugador - d2, 0)
		GameState.tiene_escudo = false
		_terminar("¡Perdiste! Daño: %d" % d2)
		return


# ESCUDO Y DAÑO×2 (consumen reservas)
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
		mensaje_central.text = "Daño ×2 activado para la próxima ronda."
		mensaje_central.visible = true
	else:
		mensaje_central.text = "No tienes daño ×2 disponible."
		mensaje_central.visible = true


# ACTUALIZAR UI
func _update_ui() -> void:
	vida_label_j.text = str(GameState.vida_jugador)
	fichas_label.text = str(GameState.fichas_jugador)
	vida_label_e.text = str(vida_enemigo)


# FIN DE RONDA
func _fin_ronda():
	if GameState.vida_jugador <= 0:
		get_tree().change_scene_to_file("res://scenes/Inicio.tscn")
	elif vida_enemigo <= 0:
		mensaje_central.text = "¡Has derrotado a Don Rico!"
		mensaje_central.visible = true
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/Shop2.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Shop2.tscn")


# IR A LA TIENDA
func _ir_tienda():
	get_tree().change_scene_to_file("res://scenes/Shop2.tscn")


# PREMIAR AL JUGADOR (+1 ficha y terminar ronda)
func _premiar(texto: String) -> void:
	GameState.fichas_jugador += 1
	_terminar(texto )


func _terminar(texto: String) -> void:
	mensaje_central.text    = texto
	mensaje_central.visible = true
	boton_pedir.disabled    = true
	boton_plantarse.disabled= true
	_update_ui()

	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(Callable(self, "_terminar_accion"))


func _terminar_accion() -> void:
	_update_ui()
	if GameState.vida_jugador <= 0:
		mensaje_central.text = "¡Perdiste la partida! Saliendo al menú principal."
		await get_tree().create_timer(2.0).timeout
		_ir_menu_principal()
	elif vida_enemigo <= 0:
		mensaje_central.text = "¡Ganaste la partida! Eres el nuevo capo."
		await get_tree().create_timer(2.0).timeout
		_ir_escena_final()  # Cambia de la tienda final a la escena de victoria
	else:
		_reiniciar_ronda()

# Nueva función para cambiar a la escena de victoria
func _ir_escena_final() -> void:
	get_tree().change_scene_to_file("res://scenes/final.tscn")  # Cambia a la escena final (victoria)


func _ir_menu_principal() -> void:
	get_tree().change_scene_to_file("res://scenes/Inicio.tscn")
