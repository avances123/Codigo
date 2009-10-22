(defrule regla-sumar-elementos
   (declare (salience 10))
   (elemento ?x)
   (elemento ?y)
=>
   (assert (elemento (+ ?x ?y)))
   (printout t (+ ?x ?y) crlf))


(defrule regla-parar
   (declare (salience 20))
   (elemento ?x)
   (test (> ?x 99999))
=>
   (halt))


(deffacts hechos-iniciales
   (elemento 1))
