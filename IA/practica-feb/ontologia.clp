; v1.0 Fabio Rueda Carrascosa

; TODO
; Clase JUGADOR	v2.0
; Clase OBJETO	v1.0
; Clase accion

(defclass JUGADOR
	(is-a USER)
	(role concrete) ;o "abstract" si no se va a crear ninguna instancia
	;; Identificador del jugador
	(slot id (type INTEGER)) 
	;; Posicion en la que se encuentra
	(slot x (type INTEGER)) 
	(slot y (type INTEGER))  
	; TODO la felicidad va de 0 a +infinito
	(slot felicidad (type INTEGER)(default 0))
	; indicadores 
	; TODO falta acotarlo de 0 a 100
	(slot hambre (type INTEGER)(default 0))
	(slot sed (type INTEGER)(default 0))
	(slot suciedad (type INTEGER)(default 0))
	(slot cansancio (type INTEGER)(default 0))
	(slot aburrimiento (type INTEGER)(default 0))
	; TODO accion a ejecutar
	; TODO obajeto que esta usando
	; TODO preferencias para cada uno de los objetos
)

(defclass OBJETO
	;; es un user?
	(is-a USER)
	(role abstract)
	;; Identificador del objeto
	(slot id (type INTEGER)) 
	;; Posicion en la que se encuentra
	(slot x (type INTEGER)) 
	(slot y (type INTEGER))  
)

(defclass COMIDA
	(is-a OBJETO)
	(role concrete)
	(slot owner (type INTEGER))
)


(deftemplate CONTROL-TURNO 
	(slot id-jugador (type INTEGER)) 
	(slot num-jugadores (type INTEGER))
)
(deftemplate FIN-TURNO
	(slot id-jugador (type INTEGER)) 
)
;; ============================================================================
;+  INSTANCIAS DE LA ONTOLOGIA
(definstances INSTANCIAS
	;; Jugadores
	([ontologia_Class1] of  JUGADOR (id 0) (x 0) (y 0))
	([ontologia_Class2] of  JUGADOR (id 1) (x 1) (y 1))
	([ontologia_Class3] of  JUGADOR (id 2) (x 2) (y 2))
	([ontologia_Class4] of  JUGADOR (id 3) (x 3) (y 3))
	;; Objetos
	([ontologia_Class5] of  COMIDA (id 3) (x 3) (y 3) (owner 0))
)
;; turno inicial del jugador 0 y número de jugadores
(deffacts turno-inicial 
	;; Hecho para saber a quien le toca
	(CONTROL-TURNO (id-jugador (random 0 3)) (num-jugadores 3)) 
)

