from django.urls import path
from langganan.views import show_langganan, show_beli

app_name = 'langganan'

urlpatterns = [
    path('', show_langganan, name='show_langganan'),
    path('beli-page/<paket>', show_beli, name='show_beli'),
    # path('beli/<paket>', beli_paket, name='beli_paket'),
]