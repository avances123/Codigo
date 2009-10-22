(defrule regla-sumar-elementos
   (declare (salience 10))
   (elemento ?x)
   (elemento ?x)
=>
   (assert (elemento (+ ?x ?x)))
   (printout t (+ ?x ?x) crlf))


(defrule regla-parar
   (declare (salience 20))
   (elemento ?x)
   (test (> ?x 99999))
=>
   (halt))


(deffacts hechos-iniciales
   (elemento 1))
