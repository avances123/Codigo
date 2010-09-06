#!/bin/python
import sys
import getopt
import psycopg2
import random
from individuo import Individuo

def escribeEnFichero():
    logfile = open('test.csv', 'a')
    logfile.write('line 2')
    logfile.close()

def conectaADB():
    # Conectamos a la base de datos
    try:
        #conn = psycopg2.connect("dbname='busqueda' user='postgres' host='localhost' password='12345'");
        conn = psycopg2.connect("dbname='busqueda' user='fabio' host='localhost' password='12345'");
    except Exception, e:
        #print "No puedo conectar a db"
        print e
        return

    return conn


def escribeEnDB(conn,tipo,a_movimientos,b_movimientos,exito):
    cur = conn.cursor()
    
    tabla='test_encontrarse'
    columnas=['tipo','a_movimientos','b_movimientos','exito']

    valores=['\'' + tipo + '\'',str(a_movimientos),str(b_movimientos),str(exito)]
    
    statement = 'INSERT INTO ' + tabla + ' (' + ','.join(columnas) + ') VALUES (' + ','.join(valores) + ')'
    #print statement
    try:
    	cur.execute(statement) 
    except Exception, e:
        print e.pgerror
    conn.commit()


def test4(conn,limite):
    """
    Test movimiento aleatorio total con los dos individuos moviendose
    """
    tipo='test4'
    # Situamos a los individuos inicialmente
    a=Individuo(random.randrange(1,borde),random.randrange(1,borde),borde)
    b=Individuo(random.randrange(1,borde),random.randrange(1,borde),borde)

    # Bucle de busqueda
    exito=False
    while (not exito):
	a.moverAContigua()
	b.moverAContigua()
	if a.movimientos >= limite:
	    break
	if b.movimientos >= limite:
	    break

	if (a.x == b.x and a.y == b.y):  # Si estan en la misma casilla... exito
	    exito=True

    if exito == False:
        print "Fracaso en test4"
    escribeEnDB(conn,tipo,a.movimientos,b.movimientos,exito)



def test3(conn,limite):
    """
    Test movimiento aleatorio a las casillas contiguas con un individuo quieto
    """
    tipo='test3'
    # Situamos a los individuos inicialmente
    a=Individuo(random.randrange(1,borde),random.randrange(1,borde),borde)
    b=Individuo(random.randrange(1,borde),random.randrange(1,borde),borde)

    # Bucle de busqueda
    exito=False
    while (not exito):
	a.moverAContigua()
	if a.movimientos >= limite:
	    break
	if (a.x == b.x and a.y == b.y):  # Si estan en la misma casilla... exito
	    exito=True

    escribeEnDB(conn,tipo,a.movimientos,b.movimientos,exito)



def test2(conn,limite):
    """
    Test movimiento aleatorio total con los dos individuos moviendose
    """
    tipo='test2'
    # Situamos a los individuos inicialmente
    a=Individuo(random.randrange(1,borde),random.randrange(1,borde),borde)
    b=Individuo(random.randrange(1,borde),random.randrange(1,borde),borde)

    # Bucle de busqueda
    exito=False
    while (not exito):
	a.moverACualquiera()
	b.moverACualquiera()
	if a.movimientos >= limite:
	    break
	if b.movimientos >= limite:
	    break
	if (a.x == b.x and a.y == b.y):  # Si estan en la misma casilla... exito
	    exito=True

    escribeEnDB(conn,tipo,a.movimientos,b.movimientos,exito)



def test1(conn,limite):
    """
    Test movimiento aleatorio total con un individuo quieto
    """
    tipo='test1'
    # Situamos a los individuos inicialmente
    a=Individuo(random.randrange(1,borde),random.randrange(1,borde),borde)
    b=Individuo(random.randrange(1,borde),random.randrange(1,borde),borde)
 
    # Bucle de busqueda
    exito=False
    while (not exito):
	# Solo muevo uno
	a.moverACualquiera()
	if a.movimientos >= limite:
	    break
	if (a.x == b.x and a.y == b.y):  # Si estan en la misma casilla... exito
	    exito=True

    escribeEnDB(conn,tipo,a.movimientos,b.movimientos,exito)


if __name__ == "__main__":
    # Limite del tablero
    borde=100

    # TODO hacerla global
    conn=conectaADB()
    for i in range(40000):
	print i
    	test1(conn,30000)
    	test2(conn,30000)
    	test3(conn,30000)
    	test4(conn,30000)


    

