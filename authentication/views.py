from django.http import HttpResponseRedirect
from django.shortcuts import render, redirect
from django.contrib import messages
from django.db import connection
import datetime

from django.urls import reverse

cursor = connection.cursor()

def login_required_custom(view_func):
    def _wrapped_view_func(request, *args, **kwargs):
        if 'username' not in request.COOKIES:
            return redirect('/')
        return view_func(request, *args, **kwargs)
    return _wrapped_view_func

def show_main(request):
    return render(request, "mainmenu.html")

def show_login(request):
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        cursor.execute("SET search_path TO pacilflix;")
        cursor.execute("SELECT * FROM PENGGUNA WHERE username = %s AND password = %s", [username, password])
        users = cursor.fetchone()

        if users is not None:
            response = HttpResponseRedirect(reverse("tayangan:show_tayangan"))
            response.set_cookie('username', users[0])
            response.set_cookie('last_login', str(datetime.datetime.now()))
            return response
        else:
            messages.info(request, 'Sorry, incorrect username or password. Please try again.')
    return render(request, 'login.html')

def show_register(request):
    if request.method == "POST":
        username = request.POST.get('username')
        password = request.POST.get('password')
        negara = request.POST.get('negara_asal')

        cursor.execute("SET search_path TO pacilflix;")
        cursor.execute("SELECT * FROM PENGGUNA WHERE username = %s", [username])
        if cursor.fetchone() is not None:
            messages.error(request, f"Username {username} sudah tersedia.")
            return render(request, 'register.html', {'form': request.POST})
        
        response = HttpResponseRedirect(reverse("authentication:show_login"))
        cursor.execute("INSERT INTO PENGGUNA (username, password, negara_asal) VALUES (%s, %s, %s)", [username, password, negara])
        messages.success(request, 'Your account has been successfully created!')
        return response
    return render(request, 'register.html')

@login_required_custom
def logout_user(request):
    response = HttpResponseRedirect(reverse("authentication:show_main"))
    for cookie in request.COOKIES:
        response.delete_cookie(cookie)
    return response