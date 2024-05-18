from django.urls import path
from save.views import daftar_unduhan, daftar_favorit, detail_favorit, hapus_unduhan, hapus_tayangan, hapus_favorit

app_name = 'save'

urlpatterns = [
    path('unduhan/', daftar_unduhan, name='daftar_unduhan'),
    path('hapus_unduhan/<str:id_tayangan>/<str:timestamp>', hapus_unduhan, name='hapus_unduhan'),
    path('favorit/', daftar_favorit, name='daftar_favorit'),
    path('detail_favorit/<str:judul>', detail_favorit, name='detail_favorit'),
    path('hapus_tayangan/<str:id_tayangan>/<str:timestamp>', hapus_tayangan, name='hapus_tayangan'),
    path('hapus_favorit/<str:timestamp>', hapus_favorit, name='hapus_favorit'),
]