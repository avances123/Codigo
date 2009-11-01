; Sat Oct 31 22:38:02 CET 2009
; 
;+ (version "3.4.1")
;+ (build "Build 537")

(deftemplate indicador
  (slot nombre
  	(type SYMBOL)
  	(allowed-values hambre sed suciedad cansancio aburrimiento)
  	(default ?NONE)
  )
  (slot valor
        (type INTEGER)
        (default 0)
; TODO el valor puede ir de 0 a 100
  )
)

(deffacts indicadores 
   (indicador (nombre hambre) (valor 0) )
   (indicador (nombre sed) (valor 0) )
   (indicador (nombre suciedad) (valor 0) )
   (indicador (nombre cansancio) (valor 0) )
   (indicador (nombre aburrimiento) (valor 0) )
)




(defclass JUGADOR
	(is-a USER)
	(role concrete))




;+  INSTANCIAS DE LA ONTOLOGIA
(definstances INSTANCIAS
	; Sat Oct 31 22:38:03 CET 2009
	; 
	;+ (version "3.4.1")
	;+ (build "Build 537")
	
	([ontologia_Class2] of  JUGADOR
	)
	
	([ontologia_Class5] of  JUGADOR
	)
	
	([ontologia_Class6] of  JUGADOR
	)
)
