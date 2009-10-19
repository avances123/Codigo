

;;CLIPS EN SU BASE DE DATOS TIENE HECHOS E INSTANCIAS

;; Fabio Rueda Carrascosa
;; Univ Carlos III de Madrid

;;Para los HECHOS es necesario:
;1º definir la plantilla
(deftemplate plant1
   (slot atrib1
       (type SYMBOL)
       (allowed-values X Y Z)
       (default Y))
   (slot atrib2
        (type INTEGER)
        (default 3))
   (slot atrib3
        (type SYMBOL)))

;; no esta en UTF8
;; 2º Introducir hechos de ese tipo en CLIPS.
;; Con deffacts forman parte de CLIPS después del comando (reset)
(deffacts hechos-plant1
  (plant1 (atrib1 X) (atrib2 1) (atrib3 ALGO))
  (plant1)
  (plant1 (atrib3 OTRO))
)

;;tambien se pueden introducir en la parte derecha de una regla con
;; (assert (plant1 (atrib1 Z)))

;;Con el comando (facts) aparecen todos los hechos que tiene CLIPS en su base de conocimiento, junto con los valores de sus atributos
;;CLIPS les da un nombre a cada uno f-XXX

;;Para las INSTANCIAS es necesario:
;;1º definir la clase (marco u objeto)
(defclass CLASE1 (is-a INITIAL-OBJECT)
   (slot atrib1
        (type SYMBOL)
        (create-accessor read-write)
        (allowed-values X Y Z)
        (default Y))
   (slot atrib2
        (type INTEGER)
        (create-accessor read-write)
        (default 3))
   (slot atrib3
        (type SYMBOL)
        (create-accessor read-write)))

;2º Introducir instancias de ese tipo en CLIPS.
;; Con definstances forman parte de CLIPS después del comando (reset)
;; Si no se le da nombre a las instancias, ej [n1], CLIPS asigna nombres 
;; por defecto [genxxx]
(definstances  instancias-clase1
  ( of CLASE1 (atrib1 X) (atrib2 1) (atrib3 ALGO))
  ( of CLASE1 )
  ( [nombre] of CLASE1 (atrib3 nombre))
)

;;tambien se pueden introducir en la parte derecha de una regla con
;; (make-instance of CLASE1 (atrib1 Z))
;; (make-instance [nombre] of CLASE1 (atrib1 Z))

;;Con el comando (instances) aparecen todos los hechos de ese tipo.
;;Si no se especifica nombre CLIPS les asigna un nombre diferente [genxxx]
;; Para ver sus atributos ejecutar comando (send [gen1] print)


(defrule prueba1
   (declare (salience 20))
   (plant1 (atrib1 ?a1) (atrib2 ?a2) (atrib3 ?a3))
   (object (is-a CLASE1) (atrib1 ?c1) (atrib2 ?c2) (atrib3 ?c3))
 =>
   (printout t "Ejecuta regla prueba1 con  plant1: " ?a1 " " ?a2 " " ?a3 )
   (printout t "  y CLASE1: " ?c1 " " ?c2 " " ?c3 crlf)
 )

(defrule prueba2
   (declare (salience 10))
   ?f1 <- (plant1 (atrib1 ?a1) (atrib2 ?a2) (atrib3 ?a3))
   ?i1 <- (object (is-a CLASE1) (atrib1 ?c1) (atrib2 ?c2) (atrib3 ?c3))
 =>
   (printout t "Ejecuta regla prueba2, plant1: " ?a1 " " ?a2 " " ?a3 )
   (printout t " y con  CLASE1: " ?c1 " " ?c2 " " ?c3 crlf)
   (modify-instance ?i1 (atrib1 X))
   (modify ?f1 (atrib3 ya))
 )


(defrule prueba3
  ?f1 <- (plant1 (atrib1 ?a1) (atrib2 ?a2) (atrib3 ?a3))
  ?i1 <- (object (is-a CLASE1) (atrib1 ?c1) (atrib2 ?c2) (atrib3 ?c3))
=>
  (printout t "Ejecutar regla prueba 3,  va borrar hecho " ?f1 " valores: " ?a1 " " ?a2 " " ?a3 )
  (printout t "  y la instancia " ?i1 " valores: " ?c1 " " ?c2 " " ?c3 crlf)
  (retract ?f1)
  (unmake-instance ?i1)
)

  
;; CLIPS> (reset)
;; CLIPS> (facts)
;; f-0     (initial-fact)
;; f-1     (plant1 (atrib1 X) (atrib2 1) (atrib3 ALGO))
;; f-2     (plant1 (atrib1 Y) (atrib2 3) (atrib3 nil))
;; f-3     (plant1 (atrib1 Y) (atrib2 3) (atrib3 OTRO))
;; For a total of 4 facts.
;; CLIPS> (instances)
;; [initial-object] of INITIAL-OBJECT
;; [gen7] of CLASE1
;; [gen8] of CLASE1
;; [nombre] of CLASE1
;; For a total of 4 instances.
;; CLIPS> (send [nombre] print)
;; [nombre] of CLASE1
;; (atrib1 Y)
;; (atrib2 3)
;; (atrib3 nombre)
;; CLIPS> (agenda)
;; 20     prueba1: f-3,[nombre]
;; 20     prueba1: f-3,[gen8]
;; 20     prueba1: f-3,[gen7]
;; 20     prueba1: f-2,[nombre]
;; 20     prueba1: f-2,[gen8]
;; 20     prueba1: f-2,[gen7]
;; 20     prueba1: f-1,[nombre]
;; 20     prueba1: f-1,[gen8]
;; 20     prueba1: f-1,[gen7]
;; 10     prueba2: f-3,[nombre]
;; 10     prueba2: f-3,[gen8]
;; 10     prueba2: f-3,[gen7]
;; 10     prueba2: f-2,[nombre]
;; 10     prueba2: f-2,[gen8]
;; 10     prueba2: f-2,[gen7]
;; 10     prueba2: f-1,[nombre]
;; 10     prueba2: f-1,[gen8]
;; 10     prueba2: f-1,[gen7]
;; 0      prueba3: f-3,[nombre]
;; 0      prueba3: f-3,[gen8]
;; 0      prueba3: f-3,[gen7]
;; 0      prueba3: f-2,[nombre]
;; 0      prueba3: f-2,[gen8]
;; 0      prueba3: f-2,[gen7]
;; 0      prueba3: f-1,[nombre]
;; 0      prueba3: f-1,[gen8]
;; 0      prueba3: f-1,[gen7]
;; CLIPS> (run 9)
;; Ejecuta regla prueba1 con  plant1: Y 3 OTRO  y CLASE1: Y 3 nombre
;; Ejecuta regla prueba1 con  plant1: Y 3 OTRO  y CLASE1: Y 3 nil
;; Ejecuta regla prueba1 con  plant1: Y 3 OTRO  y CLASE1: X 1 ALGO
;; Ejecuta regla prueba1 con  plant1: Y 3 nil  y CLASE1: Y 3 nombre
;; Ejecuta regla prueba1 con  plant1: Y 3 nil  y CLASE1: Y 3 nil
;; Ejecuta regla prueba1 con  plant1: Y 3 nil  y CLASE1: X 1 ALGO
;; Ejecuta regla prueba1 con  plant1: X 1 ALGO  y CLASE1: Y 3 nombre
;; Ejecuta regla prueba1 con  plant1: X 1 ALGO  y CLASE1: Y 3 nil
;; Ejecuta regla prueba1 con  plant1: X 1 ALGO  y CLASE1: X 1 ALGO
;; CLIPS> (agenda)
;; 10     prueba2: f-3,[nombre]
;; 10     prueba2: f-3,[gen10]
;; 10     prueba2: f-3,[gen9]
;; 10     prueba2: f-2,[nombre]
;; 10     prueba2: f-2,[gen10]
;; 10     prueba2: f-2,[gen9]
;; 10     prueba2: f-1,[nombre]
;; 10     prueba2: f-1,[gen10]
;; 10     prueba2: f-1,[gen9]
;; 0      prueba3: f-3,[nombre]
;; 0      prueba3: f-3,[gen10]
;; 0      prueba3: f-3,[gen9]
;; 0      prueba3: f-2,[nombre]
;; 0      prueba3: f-2,[gen10]
;; 0      prueba3: f-2,[gen9]
;; 0      prueba3: f-1,[nombre]
;; 0      prueba3: f-1,[gen10]
;; 0      prueba3: f-1,[gen9]
;; For a total of 18 activations.
;; CLIPS> (run 1)
;; Ejecuta regla prueba2, plant1: Y 3 OTRO y con  CLASE1: Y 3 nombre
;; CLIPS> (agenda)
;; 20     prueba1: f-4,[nombre]
;; 20     prueba1: f-4,[gen10]
;; 20     prueba1: f-4,[gen9]
;; 20     prueba1: f-1,[nombre]
;; 20     prueba1: f-2,[nombre]
;; 10     prueba2: f-4,[nombre]
;; 10     prueba2: f-4,[gen10]
;; 10     prueba2: f-4,[gen9]
;; 10     prueba2: f-1,[nombre]
;; 10     prueba2: f-2,[nombre]
;; 10     prueba2: f-2,[gen10]
;; 10     prueba2: f-2,[gen9]
;; 10     prueba2: f-1,[gen10]
;; 10     prueba2: f-1,[gen9]
;; 0      prueba3: f-4,[nombre]
;; 0      prueba3: f-4,[gen10]
;; 0      prueba3: f-4,[gen9]
;; 0      prueba3: f-1,[nombre]
;; 0      prueba3: f-2,[nombre]
;; 0      prueba3: f-2,[gen10]
;; 0      prueba3: f-2,[gen9]
;; 0      prueba3: f-1,[gen10]
;; 0      prueba3: f-1,[gen9]
;; For a total of 23 activations.

;; Si sólo tuviésemos la regla prueba3 se ejecutaría
;; CLIPS> (reset)
;; CLIPS> (facts)
;; f-0     (initial-fact)
;; f-1     (plant1 (atrib1 X) (atrib2 1) (atrib3 ALGO))
;; f-2     (plant1 (atrib1 Y) (atrib2 3) (atrib3 nil))
;; f-3     (plant1 (atrib1 Y) (atrib2 3) (atrib3 OTRO))
;; For a total of 4 facts.
;; CLIPS> (instances)
;; [initial-object] of INITIAL-OBJECT
;; [gen13] of CLASE1
;; [gen14] of CLASE1
;; [nombre] of CLASE1
;; For a total of 4 instances.
;; CLIPS> (run)
;; Va a borrar hecho <Fact-3> valores: Y 3 OTRO
;; Va a borrar instancia <Instance-nombre> valores: Y 3 nombre
;; Va a borrar hecho <Fact-2> valores: Y 3 nil
;; Va a borrar instancia <Instance-gen14> valores: Y 3 nil
;; Va a borrar hecho <Fact-1> valores: X 1 ALGO
;; Va a borrar instancia <Instance-gen13> valores: X 1 ALGO
