;; Fichero con las reglas para controlar el juego


(deftemplate TIPO-JUEGO
	;;(slot tipo (type BOOLEAN))
)

(deftemplate TIEMPO
	(slot contador (type INTEGER))
)



;; regla para cambiar turno 
(defrule cambiar-turno 
	(declare (salience 20))
	;; hay que controlar la prioridad para que solo se ejecute cuando toca, o hacerlo mediante un hecho que indique que el jugador correspondiente 
	;; ha teminado su turno. Por ejemplo se puede hacer que cada vez que un jugador realiza su turno se cree un hecho realizado-turno 
	;; El control de turno se hace con el modulo para que sea cíclico 
	?c <-(CONTROL-TURNO (id-jugador ?id) (num-jugadores ?n)) 
	?u <-(FIN-TURNO (id-jugador ?id)) 
=> 
	(retract ?u)
	(modify ?c (id-jugador (mod (+ ?id 1) ?n)))
)



