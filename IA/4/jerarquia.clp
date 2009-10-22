;i; Author: Fabio Rueda Carrascosa
;; NIA: 100035946
;; Inteligencia Artificial ITIG

;;(defglobal ?file = "camino.log")
(set-estrategy random)
;;(dribble-on 4.log)
;;(watch slots)


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
   (of ROBOT (x 4) (y 3) (orientacion Norte))
   (of META (x 5) (y 5))
   (of INTRANSITABLE (x 3) (y 3))
   ;; Artefacto para los limites
   (of ESQUINA (x 1) (y 1))
   (of ESQUINA (x 10) (y 10))
   ;; guardamos el camino que recorre
   ;;(open "camino.log" ?file "w")
)

;; Ejercicio 3
;; v1.0 Capturamos el robot y la meta con ?x e ?y (TODO quiza haya que hacer test)
;; v2.0 agregada prioridad para que se ejecute la primera
;; REGLA DE FIN
(defrule condicion-fin
   (declare (salience 30))
   ?robot <- (object (is-a ROBOT)(x ?x)(y ?y))
   ?meta  <- (object (is-a META)(x ?x)(y ?y))
   =>
   ;;(close ?file)
   (printout t "El robot llego a la meta" crlf)
   (halt)
)


;; Ejercicio 4
;; REGLAS PARA EL DESPLAZAMIENTO DEL ROBOT


;; Regla Desplazar
;; v1.0 No comprueba objetos intransitables
;; v2.0 Comprueba intransitables y crea nuevos segun pasa por las casillas para no repetir
(defrule desplazar
   (declare (salience 20)) ;;si nos podemos mover a la casilla de enfrente nos movemos
   ?robot <- (object (is-a ROBOT)(x ?x)(y ?y)(orientacion ?orientacion))
   ?desp  <- (desplazamiento (orientacion ?orientacion)(dx ?dx)(dy ?dy))
   ;; Controlamos que no se salga del tablero
   (object (is-a ESQUINA)(x ?i)(y ?j))
   (object (is-a ESQUINA)(x ?k)(y ?l))
   (test (< ?i ?k))
   (test (< ?j ?l))
   (test (>= (+ ?x ?dx) ?i))
   (test (<= (+ ?x ?dx) ?k))
   (test (>= (+ ?y ?dy) ?j))
   (test (<= (+ ?y ?dy) ?l))
   ;; estamos dentro del tablero
   (not (object (is-a INTRANSITABLE)(x =(+ ?x ?dx))(y =(+ ?y ?dy))))
   =>
   (modify-instance ?robot (x (+ ?x ?dx))(y (+ ?y ?dy)))
   ;; eureka! si paso por una casilla, esta se hace un muro y no puedo volver a pasar por ella.
   (make-instance of INTRANSITABLE (x (+ ?x ?dx))(y (+ ?y ?dy)))
   (printout t (+ ?x ?dx) " ")
   (printout t (+ ?y ?dy) crlf)
   ;;(printout ?file (+ ?x ?dx) " ")
   ;;(printout ?file (+ ?y ?dy) crlf)
)

;; Regla girar
;; v2.0 solo gira a la derecha
(defrule girar
   (declare (salience 10)) ;; si no nos podemos desplazar a la casilla de enfrente, giramos.
   ?robot <- (object (is-a ROBOT)(x ?x)(y ?y)(orientacion ?inicial))
   ;; segun el enunciado solo se puede girar a la Derecha
   ?giro <- (giro (inicial ?inicial)(sentido Derecha)(final ?final))
   =>
   (modify-instance ?robot (orientacion ?final))
)

;; Regla para cuando se queda sin poder moverse
;;(defrule para-ante-bloqueo
;;   (declare (salience 5)) ;; si no nos podemos desplazar a la casilla de enfrente, giramos.
;;   =>
;;   ;;(close ?file)
;;   (halt)
;;)


(reset)
(run)
