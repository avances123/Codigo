; Plantilla para las dos jarras
(deftemplate jarra
	(slot litros
		(type INTEGER)
		(default 0)
	)
	(slot capacidad
		(type INTEGER)
		(default 0)
	)
)

; Crea las jarras
(defrule estado-inicial


=>
	(assert (jarra (capacidad 4)))
	(assert (jarra (capacidad 3)))
)

; REGLAS
