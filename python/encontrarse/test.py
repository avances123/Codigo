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
    print statement
    try:
    	cur.execute(statement) 
    except Exception, e:
        print e.pgerror
    conn.commit()

def testDosMoviendose(conn,limite):
    tipo='0Quieto'
    # Situamos a los individuos inicialmente
    a=Individuo()
    b=Individuo()
 
    # Bucle de busqueda
    exito=False
    while (not exito):
	a.moverACualquiera()
	if a.movimientos >= limite:
	    break
	b.moverACualquiera()
	if b.movimientos >= limite:
	    break

	if (a.x == b.x and a.y == b.y):  # Si estan en la misma casilla... exito
	    exito=True

    escribeEnDB(conn,tipo,a.movimientos,b.movimientos,exito)



def testUnoQuieto(conn,limite):
    tipo='1Quieto'
    # Situamos a los individuos inicialmente
    a=Individuo()
    b=Individuo()
 
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
    # Pillamos los argumentos
    try:
        opts, args = getopt.getopt(sys.argv[1:], "h", ["help"])
    except getopt.error, msg:
        print msg
        print "for help use --help"
        sys.exit(2)
    # process options
    for o, a in opts:
        if o in ("-h", "--help"):
            print __doc__
            sys.exit(0)
    # process arguments
    for arg in args:
	pass

    # TODO hacerla global
    conn=conectaADB()
    for i in range(10000):
    	#testUnoQuieto(conn,300000)
	print i
    	testDosMoviendose(conn,300000)

    

