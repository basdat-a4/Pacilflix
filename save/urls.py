from django.urls import path
from save.views import daftar_unduhan, daftar_favorit

app_name = 'save'

urlpatterns = [
    path('unduhan/', daftar_unduhan, name='daftar_unduhan'),
    path('favorit/', daftar_favorit, name='daftar_favorit'),
]