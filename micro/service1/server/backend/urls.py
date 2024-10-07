from django.urls import path
from django.http import HttpResponse

def home_view(request):
    return HttpResponse("Hello, Django!")

urlpatterns = [
    path('', home_view),
]
