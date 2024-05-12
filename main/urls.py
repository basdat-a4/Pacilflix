from django.urls import path
from main.views import show_main
from . import views

app_name = 'main'

urlpatterns = [
    path('', show_main, name='show_main'),
    path('unduhan/', views.daftar_unduhan, name='daftar_unduhan'),
    path('favorit/', views.daftar_favorit, name='daftar_favorit'),
]