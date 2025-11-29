"""
URL configuration for the core app.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r"items", views.ItemViewSet)

urlpatterns = [
    path("", views.api_root, name="api_root"),
    path("", include(router.urls)),
]
