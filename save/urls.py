from django.urls import path
from save.views import daftar_unduhan, daftar_favorit, detail_favorit

app_name = 'save'

urlpatterns = [
    path('unduhan/', daftar_unduhan, name='daftar_unduhan'),
    path('favorit/', daftar_favorit, name='daftar_favorit'),
    # path('hapus-favorit/<int:favorit_id>/', hapus_favorit, name='hapus_favorit'),
    path('detail_favorit/<int:favorit_id>/', detail_favorit, name='detail_favorit'),
]