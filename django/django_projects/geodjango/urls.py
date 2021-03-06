from django.conf.urls.defaults import *
from django.contrib.gis import admin
from geodjango.views import horafecha_actual

# Uncomment the next two lines to enable the admin:
# from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    # Example:
    # (r'^geodjango/', include('geodjango.foo.urls')),

    # Uncomment the admin/doc line below and add 'django.contrib.admindocs' 
    # to INSTALLED_APPS to enable admin documentation:
    # (r'^admin/doc/', include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
     (r'^admin/', include(admin.site.urls)),
     (r'^ahora/$', horafecha_actual),

     #(r'^admin/(.*)', admin.site.root),

)
