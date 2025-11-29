"""
Core views for the Django application.
"""

from rest_framework import viewsets, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Item
from .serializers import ItemSerializer


class ItemViewSet(viewsets.ModelViewSet):
    """ViewSet for Item model."""

    queryset = Item.objects.all()
    serializer_class = ItemSerializer


@api_view(["GET"])
def api_root(request):
    """API root endpoint."""
    return Response(
        {
            "status": "ok",
            "message": "Django Application API",
            "version": "1.0.0",
        }
    )
