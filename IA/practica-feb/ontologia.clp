; v1.0 Fabio Rueda Carrascosa

; TODO
; Clase objeto
; Clase accion



(defclass JUGADOR
	(is-a USER)
	(role concrete) ;o "abstract" si no se va a crear ninguna instancia
	(slot id (type INTEGER))   ;; Plantilla para controlar el turno. Indica el jugador que tiene el turno actualmente y el número total de jugadores
	; felicidad
	; TODO la felicidad va de 0 a +infinito
	(slot felicidad (type INTEGER)(default 0))
	; indicadores 
	; TODO falta acotarlo de 0 a 100
	(slot hambre (type INTEGER)(default 0))
	(slot sed (type INTEGER)(default 0))
	(slot suciedad (type INTEGER)(default 0))
	(slot cansancio (type INTEGER)(default 0))
	(slot aburrimiento (type INTEGER)(default 0))
	; TODO accion a ejecutar en el proximo turno
	; TODO obajeto que esta usando
	; TODO preferencias para cada uno de los objetos
)


(deftemplate CONTROL-TURNO (slot id-jugador (type INTEGER)) (slot num-jugadores (type INTEGER)) )


;+  INSTANCIAS DE LA ONTOLOGIA
(definstances INSTANCIAS
	
	([ontologia_Class1] of  JUGADOR
		(id 0)
	)
	
	([ontologia_Class2] of  JUGADOR
		(id 2)
	)
	
	([ontologia_Class3] of  JUGADOR
		(id 2)
	)
)
;; turno inicial del jugador 0 y número de jugadores
(deffacts turno-inicial (control-turno (id-jugador 0) (num-jugadores 3)) ) ;; regla para cambiar turno 
