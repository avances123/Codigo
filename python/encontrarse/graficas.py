"""
Make a histogram of normally distributed random numbers and plot the
analytic PDF over it
"""
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.mlab as mlab
import psycopg2


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

def leeDB(conn,tipo):
    cur = conn.cursor()

    tabla='test_encontrarse'
    columnas=['tipo','a_movimientos','b_movimientos','exito']

    #valores=['\'' + tipo + '\'',str(a_movimientos),str(b_movimientos),str(exito)]

    #statement = 'INSERT INTO ' + tabla + ' (' + ','.join(columnas) + ') VALUES (' + ','.join(valores) + ')'
    statement = 'SELECT a_movimientos from test_encontrarse where tipo = \'' + tipo + '\''
    print statement
    try:
        cur.execute(statement)
    except Exception, e:
        print e.pgerror
    rows = cur.fetchall()
    return rows
    #conn.commit()




conn = conectaADB()
x = leeDB(conn,'test1')
#print x
print len(x)


fig = plt.figure()
ax = fig.add_subplot(111)

# the histogram of the data
#ax.hist(x, 50, normed=1, facecolor='green', alpha=0.75)
ax.hist(x,100)

# hist uses np.histogram under the hood to create 'n' and 'bins'.
# np.histogram returns the bin edges, so there will be 50 probability
# density values in n, 51 bin edges in bins and 50 patches.  To get
# everything lined up, we'll compute the bin centers
#bincenters = 0.5*(bins[1:]+bins[:-1])
# add a 'best fit' line for the normal PDF
#y = mlab.normpdf( bincenters, mu, sigma)
#l = ax.plot(bincenters, y, 'r--', linewidth=1)

ax.set_xlabel('Smarts')
ax.set_ylabel('Probability')
#ax.set_title(r'$\mathrm{Histogram\ of\ IQ:}\ \mu=100,\ \sigma=15$')
#ax.set_xlim(40, 160)
#ax.set_ylim(0, 0.03)
ax.grid(True)

plt.show()
