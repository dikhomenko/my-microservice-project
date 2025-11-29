"""
Serializers for the Django application.
"""

from rest_framework import serializers
from .models import Item


class ItemSerializer(serializers.ModelSerializer):
    """Serializer for Item model."""

    class Meta:
        model = Item
        fields = ["id", "name", "description", "created_at", "updated_at"]
        read_only_fields = ["created_at", "updated_at"]
