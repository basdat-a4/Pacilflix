from django.shortcuts import render

# Create your views here.
def show_trailer(request):
    return render(request, "trailer.html")

def show_tayangan(request):
    context = {
        'username': request.COOKIES.get('username')
    }
    return render(request, 'tayangan.html', context)


def show_film(request):
    context = {
        'username': request.COOKIES.get('username')
    }
    return render(request, "film.html", context)

def show_series(request):
    context = {
        'username': request.COOKIES.get('username')
    }
    return render(request, "series.html", context)

def show_episode(request):
    context = {
        'username': request.COOKIES.get('username')
    }
    return render(request, "episode.html", context)