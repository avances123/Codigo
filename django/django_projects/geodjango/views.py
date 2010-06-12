from django.http import HttpResponse
import datetime

def horafecha_actual(peticion):
    ahora = datetime.datetime.now()
    html = "<html><body>Ahora es %s.</body></html>" % ahora
    return HttpResponse(html)

