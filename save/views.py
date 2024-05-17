from django.shortcuts import render, redirect
from django.db import connection
from django.http import JsonResponse

def daftar_unduhan(request):
    if request.user.is_authenticated:
        username = request.user.username
        with connection.cursor() as cursor:
            cursor.execute("""
                           SELECT id_tayangan, username, judul, timestamp
                           FROM TAYANGAN_TERUNDUH
                           WHERE username = %s
                           """, [username])
            unduhan_list = cursor.fetchall()
        return render(request, 'daftar_unduhan.html', {'unduhan_list': unduhan_list, 'user': request.user})
    else:
        return render(request, 'daftar_unduhan.html', {'user': request.user})


def daftar_favorit(request):
    if request.user.is_authenticated:
        username = request.user.username
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT id_favorit, judul, timestamp
                FROM DAFTAR_FAVORIT
                WHERE username = %s
                """, [request.user.username])
            favorit_list = cursor.fetchall()
        return render(request, 'daftar_favorit.html', {'favorit_list': favorit_list})
    else:
        return render(request, 'daftar_favorit.html', {'user': request.user})
    

def detail_favorit(request, favorit_id):
    if request.user.is_authenticated:
        username = request.user.username
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT t.judul, t.id_tayangan
                FROM TAYANGAN t
                JOIN DAFTAR_FAVORIT_DETAIL dfd ON t.id_tayangan = dfd.id_tayangan
                WHERE dfd.id_favorit = %s
                """, [favorit_id])
            tayangan_list = cursor.fetchall()
        return render(request, 'detail_favorit.html', {'tayangan_list': tayangan_list, 'favorit_id': favorit_id, 'user': request.user})
    else:
        return redirect('login')
    

def hapus_favorit(request, favorit_id):
    if request.user.is_authenticated:
        username = request.user.username
        try:
            with connection.cursor() as cursor:
                cursor.execute("""
                    DELETE FROM DAFTAR_FAVORIT
                    WHERE id_favorit = %s AND username = %s
                """, [favorit_id, request.user.username])
            return JsonResponse({'success': True})
        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)})
