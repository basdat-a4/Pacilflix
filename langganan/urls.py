from django.urls import path
from langganan.views import show_langganan, beli_langganan

app_name = 'langganan'

urlpatterns = [
    path('', show_langganan, name='show_langganan'),
    path('beli/', beli_langganan, name='beli_langganan'),
]