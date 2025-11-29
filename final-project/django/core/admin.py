"""
Admin configuration for the core app.
"""

from django.contrib import admin
from .models import Item


@admin.register(Item)
class ItemAdmin(admin.ModelAdmin):
    """Admin configuration for Item model."""

    list_display = ["name", "created_at", "updated_at"]
    search_fields = ["name", "description"]
    list_filter = ["created_at"]
