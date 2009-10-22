; Fabio Rueda Carrascosa
; NIA: 100035946
; Ejercicios Sesion 3 IA ITIG v.1.0



; Definicion de las clases EJERCICIO 1
(defclass ANIMAL (is-a INITIAL-OBJECT)
	(slot nombre)
	(slot piel)
	(slot vuela
		(default no)
	)
	(slot razona
		(default no)
	)
)
(defclass MAMIFERO (is-a ANIMAL)
	(slot piel
		(default pelo)
	)
)
(defclass AVE (is-a ANIMAL)
	(slot piel
		(default plumas)
	)
	(slot vuela
		(default si)
	)
)
(defclass HOMBRE (is-a MAMIFERO)
	(slot razona
		(default si)
	)
)
(defclass ALBATROS (is-a AVE)
)
(defclass PINGUINO (is-a AVE)
	(slot vuela
		(default no)
	)

)

; EJERCICIO 2
(defrule estado-inicial

=>
	(make-instance of HOMBRE (nombre PEPE))
	(make-instance of ALBATROS (nombre ALF))
	(make-instance of PINGUINO (nombre CHILLY))
)

; EJERCICIO 3
(defrule imprimir_pinguinos
	?p <- (object (is-a PINGUINO))
=>
	; TODO : Extraer el nombre del objeto ?p para imprimirlo
	(printout t "El nombre del pinguino" crlf)
	(unmake-instance ?p)   ;para que no se vuelva a imprimir y pare
)


