; v1.0 Fabio Rueda Carrascosa 20091119
; v1.1 Fabio Rueda Carrascosa 20100719

; TODO
; Clase JUGADOR	v2.0
; Clase OBJETO	v2.0



(defclass JUGADOR
	(is-a USER) ;clase del sistema, creo que es initial-object
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


; Clase abstacta principal
(defclass OBJETO
	;; es un user?
	(is-a USER)
	(role abstract)
	;; Identificador del objeto
	(slot id (type INTEGER)) 
	;; Posicion en la que se encuentra
	(slot x (type INTEGER)) 
	(slot y (type INTEGER))  
	;; Un objeto puede estar ocupado o libre
	(slot disponible (type SYMBOL) (allowed-values si no)(default si))  
)

; Objetos como ajedrez, ducha, sofa o bocadillo de calamares
(defclass OBJETO-COMIDA
	(is-a OBJETO)
	(role concrete)
	; owner tiene el id del jugador
	(slot owner (type INTEGER))
	(slot nombre (type STRING))
)
(defclass OBJETO-BEBIDA
	(is-a OBJETO)
	(role concrete)
	; owner tiene el id del jugador
	(slot owner (type INTEGER))
	(slot nombre (type STRING))
)


(defclass OBJETO-DESCANSO
	(is-a OBJETO)
	(role concrete)
	(slot nombre (type STRING))
)

(defclass OBJETO-ASEO
	(is-a OBJETO)
	(role concrete)
	(slot nombre (type STRING))
)

(defclass OBJETO-JUEGO
	(is-a OBJETO)
	(role concrete)
	(slot nombre (type STRING))
)

(defclass ORDENADOR
	(is-a OBJETO)
	(role concrete)
)

(defclass NEVERA
	(is-a OBJETO)
	(role concrete)
)


(deftemplate PREFERENCIA-OBJETO
	; el id del personaje , el enunciado habla algo
	; de grupos de personajes... TODO preguntar
	(slot personaje (type INTEGER))
	; el nombre del objeto, se podria poner el id
	; pero con el nombre conseguimos saber la preferencia
	; que tiene por el ajedrez, aunque haya 14 tableros.
	(slot objeto (type STRING))
	; de 0 a 10
	(slot preferencia (type INTEGER))
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
	([ontologia_Class5] of  OBJETO-COMIDA (id 3) (x 3) (y 3) (owner 0))
)
;; turno inicial del jugador 0 y número de jugadores
(deffacts turno-inicial 
	;; Hecho para saber a quien le toca
	(CONTROL-TURNO (id-jugador (random 0 3)) (num-jugadores 3))
)


;; facts que contienen las preferencias por los objetos de los personajes
(deffacts preferencias-objetos
	(PREFERENCIA-OBJETO (personaje 0) (objeto "ajedrez") (preferencia 5)) 
	(PREFERENCIA-OBJETO (personaje 1) (objeto "ajedrez") (preferencia 4)) 
	(PREFERENCIA-OBJETO (personaje 2) (objeto "ajedrez") (preferencia 6)) 
	(PREFERENCIA-OBJETO (personaje 3) (objeto "ajedrez") (preferencia 7)) 
)
