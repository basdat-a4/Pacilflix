from django.urls import path
from tayangan.views import show_tayangan, show_trailer, show_film, show_episode, show_series 

app_name = 'tayangan'

urlpatterns = [
    path('tayangan/', show_tayangan, name='show_tayangan'),
    path('trailer/', show_trailer, name='show_trailer'),
    path('film/', show_film, name='show_film'),
    path('series/', show_series, name='show_series'),
    path('episode/', show_episode, name='show_episode')
]