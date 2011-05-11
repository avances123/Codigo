#!/bin/python
import sys
import getopt
import psycopg2
import random
from individuo import Individuo,Tablero


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

def test6(conn,limite):
    """
    Test movimiento aleatorio total con dos individuos moviendose con memoria
    """
    tipo='test6'
    # Situamos a los individuos inicialmente
    a=Individuo(random.randrange(1,borde),random.randrange(1,borde),borde)
    b=Individuo(random.randrange(1,borde),random.randrange(1,borde),borde)
 
    t1=Tablero()
    t2=Tablero()

    # Bucle de busqueda
    exito=False
    while (exito == False):

        a.x,a.y = t1.dameCasilla()
        b.x,b.y = t2.dameCasilla()

	if a.x == -1 or b.x == -1:
	    break        

        a.movimientos += 1
        b.movimientos += 1

	if a.movimientos >= limite:
	    break
	if b.movimientos >= limite:
	    break

	if (a.x == b.x and a.y == b.y):  # Si estan en la misma casilla... exito
	    exito=True

    print tipo,':',a.movimientos
    escribeEnDB(conn,tipo,a.movimientos,b.movimientos,exito)




def test5(conn,limite):
    """
    Test movimiento aleatorio total con un individuo quieto con memoria
    """
    tipo='test5'
    # Situamos a los individuos inicialmente
    a=Individuo(random.randrange(1,borde),random.randrange(1,borde),borde)
    b=Individuo(random.randrange(1,borde),random.randrange(1,borde),borde)
 
    t=Tablero()

    # Bucle de busqueda
    exito=False
    while (exito == False):
        a.x,a.y = t.dameCasilla()
        a.movimientos += 1

	if a.movimientos >= limite:
	    break
	if (a.x == b.x and a.y == b.y):  # Si estan en la misma casilla... exito
	    exito=True

    print tipo,':',a.movimientos
    escribeEnDB(conn,tipo,a.movimientos,b.movimientos,exito)



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

def usage():
    print "-h --help\tMuestra esta pantalla"
    print "-b --borde\tEspecifica el numero de casillas de lado para el tablero"
    print "-n --numsims\tEspecifica el numero de simulaciones que se hara de cada test"
    print "-m --maxmovs\tEspecifica el numero maximo de movimientos que pueden hacer los individuos"


if __name__ == "__main__":
    # Variables por defecto de la ejecucion
    borde=100
    numsims=10000
    maxmovs=20000

    # Procesamos los parametros de entrada
    try:                                
        opts, args = getopt.getopt(sys.argv[1:], "hb:n:m:", ["help", "borde=","numsims=","maxmovs="])
    except getopt.GetoptError:          
        usage()                         
        sys.exit(2)      
    for opt, arg in opts:                
        if opt in ("-h", "--help"):      
            usage()                     
            sys.exit()              
        elif opt == ('-b', "--borde"):                
            borde = int(arg)              
        elif opt in ("-n", "--numsims"): 
            numsims = int(arg)     
        elif opt in ("-m", "--maxmovs"): 
            maxmovs = arg     


#    t=Tablero()
#    x,y = t.dameCasilla()
#    print x,y
#    sys.exit()

    conn=conectaADB()
    for i in range(numsims):
	print i
    	test1(conn,maxmovs)
    	test2(conn,maxmovs)
    	test3(conn,maxmovs)
    	test4(conn,maxmovs)
    	test5(conn,maxmovs)
    	test6(conn,maxmovs)


    

