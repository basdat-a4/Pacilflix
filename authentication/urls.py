from django.urls import path
from authentication.views import show_login, show_register, show_main, logout_user

app_name = 'authentication'

urlpatterns = [
    path('', show_main, name='show_main'),
    path('login/', show_login, name='show_login'),
    path('register/', show_register, name='show_register'),
    path('logout/', logout_user, name='logout'),
]