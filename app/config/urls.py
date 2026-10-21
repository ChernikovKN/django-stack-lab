
from django.urls import path
from django.http import HttpResponse, JsonResponse
from django.db import connection


def index(request):
    return HttpResponse(
        "Django staging v2!\n"
    )


def health(request):
    with connection.cursor() as cursor:
        cursor.execute("SELECT 1")
        cursor.fetchone()

    return JsonResponse({
        "status": "ok",
        "database": "available",
    })


urlpatterns = [
    path("", index),
    path("health/", health),
]
