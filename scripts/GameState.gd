extends Node

# —————————————————————————————————————————————
#  VARIABLES GLOBALES (ahora son contadores, no simples booleanos)
# —————————————————————————————————————————————
var vida_jugador : int = 100    # Vida actual del jugador
var fichas_jugador : int = 100  # Fichas actuales

# En lugar de “carta_escudo_comprada: bool”, usamos este contador:
var reservas_escudo : int = 0      # Cuántas “cartas de escudo” compradas (sin usar)
var reservas_dano_x2 : int = 0     # Cuántas “cartas de daño×2” compradas (sin usar)
var reservas_vida : int = 0        # Cuántas “cartas de +20 vida” compradas (sin usar)

# Durante combate, estos flags indican si el efecto está activo para la ronda actual:
var tiene_escudo : bool = false
var dano_x2_activo : bool = false

# —————————————————————————————————————————————
#  RESETEAR ESTADO (al iniciar partida o nueva partida)
# —————————————————————————————————————————————
func resetear_estado() -> void:
	vida_jugador = 100
	fichas_jugador = 100
	tiene_escudo = false
	dano_x2_activo = false

	# Reiniciar los contadores globales de cartas
	reservas_escudo = 0
	reservas_dano_x2 = 0
	reservas_vida = 0

# —————————————————————————————————————————————
#  APLICAR ESCUDO Y DAÑO ×2 (durante combate)
# —————————————————————————————————————————————
func aplicar_escudo(dano: int) -> int:
	if tiene_escudo:
		dano = 0
		tiene_escudo = false
	return dano

func aplicar_dano_x2(dano: int) -> int:
	if dano_x2_activo:
		dano *= 2
		dano_x2_activo = false
	return dano

# —————————————————————————————————————————————
#  FUNCIONES DE COMPRA (incrementan contadores)
# —————————————————————————————————————————————

# Compra “+20 de vida” (costo 3 fichas). Devuelve true si se compró, false si no hay fichas suficientes.
func comprar_vida() -> bool:
	var costo = 3
	if fichas_jugador >= costo:
		fichas_jugador -= costo
		vida_jugador += 20       # Suma inmediatamente 20 de vida
		reservas_vida += 1       # Guarda en “reserva” que tienes 1 carta extra de vida
		return true
	return false

# Compra “Escudo” (costo 4 fichas). Devuelve true si se compró, false si no hay fichas suficientes.
func comprar_escudo() -> bool:
	var costo = 4
	if fichas_jugador >= costo:
		fichas_jugador -= costo
		reservas_escudo += 1     # Guarda en reserva un escudo
		return true
	return false

# Compra “Daño×2” (costo 5 fichas). Devuelve true si se compró, false si no hay fichas suficientes.
func comprar_dano_x2() -> bool:
	var costo = 5
	if fichas_jugador >= costo:
		fichas_jugador -= costo
		reservas_dano_x2 += 1    # Guarda en reserva un daño×2
		return true
	return false
