from django.urls import path
from contributor.views import show_pemain, show_penulis, show_sutradara, show_contributors

app_name = 'contributor'

urlpatterns = [
    path('', show_contributors, name='show_contributors'),
    path('pemain/', show_pemain, name='show_pemain'),
    path('penulis/', show_penulis, name='show_penulis'),
    path('sutradara/', show_sutradara, name='show_sutradara'),
]