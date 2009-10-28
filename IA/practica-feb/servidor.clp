(defrule asignar-turno
   (declare (salience 10))
   ?player1 <- (object (is-a JUGADOR)(SIGUIENTE null))
   ?player2 <- (object (is-a JUGADOR)(SIGUIENTE null))
   ;; segun el enunciado solo se puede girar a la Derecha
   =>
   (modify-instance ?player1(SIGUIENTE ?player2))
)

