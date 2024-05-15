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

# Create your views here.
cursor = connection.cursor()

def show_main(request):
    return render(request, "mainmenu.html")

def show_login(request):
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')

        with connection.cursor() as cursor:
            cursor.execute("SET search_path TO pacilflix;")
            cursor.execute("SELECT * FROM PENGGUNA WHERE username = %s AND password = %s", [username, password])
            user = cursor.fetchone()

        if user:
            # context = {
            #     'username': username,
            # }
            return redirect('tayangan:show_tayangan')
        else:
            messages.error(request, 'Sorry, incorrect username or password. Please try again.')
            return render(request, 'login.html')

    return render(request, 'login.html')

def show_register(request):
    if request.method == "POST":
        username = request.POST.get('username')
        password = request.POST.get('password')
        negara = request.POST.get('negara_asal')

        with connection.cursor() as cursor:
            # Cek apakah username sudah ada
            cursor.execute("SET search_path TO pacilflix;")
            cursor.execute("SELECT * FROM PENGGUNA WHERE username = %s", [username])
            users = cursor.fetchmany()

            # Jika username sudah ada
            if len(users) > 0:
                messages.error(request, "Username yang Anda gunakan sudah tersedia.")
                return render(request, 'register.html', {'form': request.POST})

            # Cek kekuatan password
            if len(password) < 8:
                messages.error(request, "Password minimal harus 8 karakter.")
                return render(request, 'register.html', {'form': request.POST})

            # Jika semua validasi terpenuhi
            cursor.execute("INSERT INTO pengguna (username, password, negara_asal) VALUES (%s, %s, %s)", [username, password, negara])
            messages.success(request, 'Your account has been successfully created!')
            return redirect('authentication:show_login')
    return render(request, 'register.html')

def logout_user(request):
    request.session.flush()
    return redirect('authentication:show_main')