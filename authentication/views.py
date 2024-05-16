from django.shortcuts import render
from django.http import HttpResponse, HttpResponseRedirect
from django.shortcuts import render
from django.shortcuts import render
from django.http import HttpResponseRedirect
from django.urls import reverse
from django.shortcuts import redirect
from django.contrib import messages  
from django.http import HttpResponseRedirect
from django.urls import reverse
from django.shortcuts import redirect
from django.db import connection
from django.contrib.auth import logout
import datetime

# Create your views here.
cursor = connection.cursor()

def show_main(request):
    return render(request, "mainmenu.html")

def show_login(request):
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        cursor.execute("SET search_path TO pacilflix;")
        cursor.execute(f"SELECT * FROM PENGGUNA P WHERE P.username = '{username}' AND P.password = '{password}'")
        users = cursor.fetchone()

        if users is not None:
            request.session['username'] = users[0]
            response = redirect('tayangan:show_tayangan')
            response.set_cookie('username', users[0])
            response.set_cookie('last_login', str(datetime.datetime.now()))
            return response
        else:
            messages.info(request, 'Sorry, incorrect username or password. Please try again.')
    context = {}
    return render(request, 'login.html', context)

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

        cursor.execute("INSERT INTO pengguna (username, password, negara_asal) VALUES (%s, %s, %s)", [username, password, negara])
        messages.success(request, 'Your account has been successfully created!')
        return redirect('authentication:show_login')

    return render(request, 'register.html')

def logout_user(request):
    response = redirect('authentication:show_main')
    for cookie in request.COOKIES:
        response.delete_cookie(cookie)
    return response