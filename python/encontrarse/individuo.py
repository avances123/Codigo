#!/bin/python

import random

class Individuo:

 
    def moverACualquiera(self):
        self.x=random.randrange(1,100)   
        self.y=random.randrange(1,100)   
	self.movimientos += 1
	
    def __init__(self,x=random.randrange(1,100),y=random.randrange(1,100)):
        self.x=x
        self.y=y
	self.movimientos=0
