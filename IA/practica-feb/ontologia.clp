; v1.0 Fabio Rueda Carrascosa

; TODO
; Clase objeto
; Clase accion



(defclass JUGADOR
	(is-a USER)
	(role concrete) ;o "abstract" si no se va a crear ninguna instancia
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




;+  INSTANCIAS DE LA ONTOLOGIA
(definstances INSTANCIAS
	; Sat Oct 31 22:38:03 CET 2009
	; 
	;+ (version "3.4.1")
	;+ (build "Build 537")
	
	([ontologia_Class1] of  JUGADOR
	)
	
	([ontologia_Class2] of  JUGADOR
	)
	
	([ontologia_Class3] of  JUGADOR
	)
)
