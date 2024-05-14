from django.shortcuts import render

# Create your views here.
def show_trailer(request):
    return render(request, "trailer.html")

def show_tayangan(request):
    return render(request, "tayangan.html")

def show_film(request):
    return render(request, "film.html")

def show_series(request):
    return render(request, "series.html")

def show_episode(request):
    return render(request, "episode.html")