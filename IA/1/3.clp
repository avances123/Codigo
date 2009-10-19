;; Para el caso inicial
(defrule resta
	(declare (salience 10))
	?z <- (elemento ?x)
=>
	(assert (elemento (- ?x 1)))
)
;; se multiplican los dos numeros y al menor, se le resta 1,
;; en el mayor esta el factorial
(defrule multiplicacion
	(declare (salience 20))
	?w <- (elemento ?x)
	?z <- (elemento ?y)
	(test (< ?x ?y))
=>
	(assert (elemento (* ?x ?y)))
	(assert (elemento (- ?x 1)))
	(retract ?w)
	(retract ?z)
	(printout t (* ?x ?y) crlf)
)
	

;; paramos si existe algun numero que sea 1, y lo borramos 
;; quedandonos solo el hecho que contiene el factorial.
(defrule regla-parar
   	(declare (salience 30))
   	?z <- (elemento ?x)
   	(test (= ?x 1))
=>
	;(printout t ?x crlf)
	(retract ?z)	
   	(halt)
)


(deffacts hechos-iniciales
   (elemento 10))
