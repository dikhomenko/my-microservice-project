"""
URL configuration for dina_app project.

"""

from django.contrib import admin
from django.urls import path
from django.http import HttpResponse


def home(request):
    return HttpResponse(
        "<h1>Welcome to Dina Django Project!</h1><p>Django + PostgreSQL + Nginx is running successfully.</p>"
    )


urlpatterns = [
    path("admin/", admin.site.urls),
    path("", home, name="home"),
]
