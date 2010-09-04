#!/bin/python

import random

class Individuo:

    def moverAContigua(self):
	exito=False
	while exito==False:
    	    incx = random.choice([-1,0,1])
 	    incy = random.choice([-1,0,1])
	    if self.x+incx > 0 and self.x+incx <= self.borde and self.y+incy > 0 and self.y+incy <= self.borde:
		exito=True
            if incx == 0 and incy == 0:
                exito=False
   	# Aplicamos el incremento
        self.x += incx
        self.y += incy
        self.movimientos += 1



    def moverACualquiera(self):
        self.x=random.randrange(1,self.borde)   
        self.y=random.randrange(1,self.borde)   
	self.movimientos += 1
	
    def __init__(self,x,y,borde=100):
        self.x=x
        self.y=y
	self.movimientos=0
	self.borde=borde
