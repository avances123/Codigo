;; Author: Fabio Rueda Carrascosa
;; NIA: 100035946
;; Inteligencia Artificial ITIG

(dribble-on 4.log)
(watch slots)


;;; ******************************************
;;; JERAQUIA DE CLASES
;;; ******************************************
;;Clase abstracta genérica de la que heredan las otras
(defclass OBJETO-POSICIONABLE (is-a INITIAL-OBJECT)
  (slot x
    (type INTEGER))
  (slot y
    (type INTEGER)
  )
)

;;Clase para representar al robo
(defclass ROBOT (is-a OBJETO-POSICIONABLE)
  (slot orientacion
    (type SYMBOL)
    (allowed-values Norte Sur Este Oeste)
    (default Norte)
  )
)

;;Clase para representar la casilla final a la que quiere llegar el robot
(defclass META (is-a OBJETO-POSICIONABLE))

;; Clase para representar las casillas por las que no puede pasar el robot
;; Inicialmente los muros serán de este tipo y luego según
;; el robot visita una casilla habrá que hacer una instancia para indicar
;; que no puede volver a pasar por ella
(defclass INTRANSITABLE (is-a OBJETO-POSICIONABLE))

(deftemplate giro
  (slot inicial
  	(type SYMBOL)
  	(allowed-values Norte Sur Este Oeste)
  	(default ?NONE)
  )
  (slot sentido
  	(type SYMBOL )
  	(allowed-values Izquierda Derecha) 
  	(default ?NONE)
  )
  (slot final
  	(type SYMBOL)
  	(allowed-values Norte Sur Este Oeste)
  	(default ?NONE)
  )
)
 ;;; ******************************************
;;; PLANTILLAS AUXILIARES
;;; ******************************************
;;Plantillas para facilitar el giro del robot. 
;;Si el robot tiene una orientacion inicial, y gira en un sentido, con esta
;;plantilla obtenemos la orientación final en que quedará el robot
 
(deffacts plantillas_giro 
   (giro (inicial Norte) (sentido  Derecha) (final Este))
   (giro (inicial Este ) (sentido  Derecha) (final Sur))
   (giro (inicial Sur  ) (sentido  Derecha) (final Oeste))
   (giro (inicial Oeste) (sentido  Derecha) (final Norte))

   (giro (inicial Norte) (sentido Izquierda) (final Oeste))
   (giro (inicial Oeste) (sentido Izquierda) (final Sur))
   (giro (inicial Sur)   (sentido Izquierda) (final Este)) 
   (giro (inicial Este ) (sentido Izquierda) (final Norte))
)

;;Plantillas para facilitar el avance del robot
;;Si el robot esta en la orientación indicada, 'orientacion'
;;y avanza (solo puede avanzar una casilla cada vez en su orientación)
;;el incremento en x e y, con respecto a la situación actual del robot, 
;;viene determinado por 'dx' y 'dy'
;;Suponemos que el origen de coordenadas (0,0) está en la 
;;esquina superior izquierda
(deftemplate desplazamiento
  (slot orientacion
  	(type SYMBOL)
  	(allowed-values Norte Sur Este Oeste)
  	(default ?NONE)
  )
  (slot dx
        (type INTEGER)
        (default 0)
  )
  (slot dy
        (type INTEGER)
        (default 0)
  )
)

(deffacts plantillas_desplazamiento 
   (desplazamiento (orientacion Norte) (dx  0) (dy -1))
   (desplazamiento (orientacion Este)  (dx  1) (dy  0))
   (desplazamiento (orientacion Sur )  (dx  0) (dy  1))
   (desplazamiento (orientacion Oeste) (dx -1) (dy  0))

)


;; Ejercicio 2
;; v1.0 El robot, la meta y un objeto intransitable, (las 100 casillas no se crean)
;; v2.0 Agregadas esquinas (creado un tipo nuevo)
;; INSTANCIAS INICIALES

(defclass ESQUINA (is-a OBJETO-POSICIONABLE))

(definstances estado_inicial
   (of ROBOT (x 2) (y 2) (orientacion Norte))
   (of META (x 5) (y 5))
   (of INTRANSITABLE (x 3) (y 3))
   (of ESQUINA (X 1) (Y 1))
   (of ESQUINA (X 1) (Y 10))
   (of ESQUINA (X 10) (Y 1))
   (of ESQUINA (X 10) (Y 10))
)

;; Ejercicio 3
;; v1.0 Capturamos el robot y la meta con ?x e ?y (TODO quiza haya que hacer test)
;; REGLA DE FIN
(defrule condicion-fin
   ?robot <- (object (is-a ROBOT)(x ?x)(y ?y))
   ?meta  <- (object (is-a META)(x ?x)(y ?y))
   =>
   (halt)
)


;; Ejercicio 4
;; REGLAS PARA EL DESPLAZAMIENTO DEL ROBOT


;; Regla Desplazar
;; v1.0 No comprueba objetos intransitables
(defrule desplazar
   (declare (salience 20))
   ?robot <- (object (is-a ROBOT)(x ?x)(y ?y))
   ?desp  <- (desplazamiento (orientacion ?orientacion)(dx ?dx)(dy ?dy))
   ;; Controlamos que no se salga del tablero
   (test (<= (+ ?x ?dx) 10))
   (test (>= (+ ?x ?dx) 1))
   (test (<= (+ ?y ?dy) 10))
   (test (>= (+ ?y ?dy) 1))
   ;;(object (is-a INTRANSITABLE)(x ?x1 )(y ?y1))
   ;;(not (object (is-a INTRANSITABLE)(x ?x2)(y ?y2)))
   ;;(test (= (+ ?x ?dx) ?x1))
   ;;(test (= (+ ?y ?dy) ?y1))
   =>
   (modify-instance ?robot (x (+ ?x ?dx))(y (+ ?y ?dy)))
)

;; Regla girar
(defrule girar
   (declare (salience 10))
   ?robot <- (object (is-a ROBOT)(x ?x)(y ?y)(orientacion ?inicial))
   ;; (giro (inicial Norte) (sentido  Derecha) (final Este))
   ?giro <- (giro (inicial ?inicial)(sentido ?sentido)(final ?final))
   =>
   (modify-instance ?robot (orientacion ?final))
)



(reset)
(agenda)
