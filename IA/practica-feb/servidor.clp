;; Fichero con las reglas para controlar el juego


;; regla para cambiar turno 
(defrule cambiar-turno 
	;; hay que controlar la prioridad para que solo se ejecute cuando toca, o hacerlo mediante un hecho que indique que el jugador correspondiente 
	;; ha teminado su turno. Por ejemplo se puede hacer que cada vez que un jugador realiza su turno se cree un hecho realizado-turno 
	;; El control de turno se hace con el modulo para que sea cíclico 
	?c <-(control-turno (id-jugador ?id) (num_jugadores ?n)) 
	?u <-(realizado-turno ?id) 
=> 
	(retract ?u)
	(modify ?c (id-jugador (mod (+ ?id 1) ?n)))
)
