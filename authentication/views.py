from django.shortcuts import render

# Create your views here.
def show_login(request):
    return render(request, "login.html")

def show_register(request):
    return render(request, "register.html")