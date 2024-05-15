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
            response = redirect('tayangan:show_tayangan')  # Redirect to the desired page after login
            response.set_cookie('username', username, max_age=86400)  # Set cookie to store username with 1 day expiration
            return response
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

            # Jika semua validasi terpenuhi
            cursor.execute("INSERT INTO pengguna (username, password, negara_asal) VALUES (%s, %s, %s)", [username, password, negara])
            messages.success(request, 'Your account has been successfully created!')
            return redirect('authentication:show_login')
    return render(request, 'register.html')

def logout_user(request):
    response = redirect('authentication:show_main')  # Redirect to the main menu
    response.delete_cookie('username')  # Delete the 'username' cookie
    request.session.flush()
    return response