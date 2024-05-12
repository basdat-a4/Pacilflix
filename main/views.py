from django.shortcuts import render

# Create your views here.
def show_main(request):
    return render(request, "mainmenu.html")

def daftar_unduhan(request):
    # context
    return render(request, 'daftar_unduhan.html')

def daftar_favorit(request):
    # context
    return render(request, 'daftar_favorit.html' )