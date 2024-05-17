from django.shortcuts import render, redirect
from django.db import connection

def daftar_unduhan(request):
        username = request.COOKIES["username"]
        with connection.cursor() as cursor:
            cursor.execute("SET search_path TO Pacilflix;")
            cursor.execute("""
                            SELECT T.judul, TT.timestamp
                            FROM TAYANGAN T
                            JOIN TAYANGAN_TERUNDUH TT ON T.id = TT.id_tayangan;
                            """, [username])
            unduhan_list = cursor.fetchall()
            context = {
                'username': username,
                'unduhan_list': unduhan_list,
            }
        return render(request, 'daftar_unduhan.html', context)

def daftar_favorit(request):
        username = request.COOKIES["username"]
        with connection.cursor() as cursor:
            cursor.execute("SET search_path TO Pacilflix;")
            cursor.execute("""
                SELECT judul, timestamp
                FROM DAFTAR_FAVORIT
                WHERE username = %s
                """, [username])
            favorit_list = cursor.fetchall()
            context = {
                'username': username,
                'favorit_list': favorit_list,
            }
        return render(request, 'daftar_favorit.html', {'favorit_list': favorit_list})
    

def detail_favorit(request, favorit_id):
        username = request.COOKIES["username"]
        with connection.cursor() as cursor:
            cursor.execute("SET search_path TO Pacilflix;")
            cursor.execute("""
                SELECT T.judul, T.id_tayangan
                FROM TAYANGAN T
                JOIN DAFTAR_FAVORIT_DETAIL DFD ON T.id_tayangan = DFD.id_tayangan
                WHERE DFD.id_favorit = %s
                """, [favorit_id])
            tayangan_list = cursor.fetchall()
        return render(request, 'detail_favorit.html', {'tayangan_list': tayangan_list, 'favorit_id': favorit_id, 'user': request.user})
    

def delete_unduhan(request):
    if request.method == 'POST':
        id_tayangan = request.POST.get('id_tayangan')
        username = request.COOKIES.get('username')
        with connection.cursor() as cursor:
            cursor.execute("SET search_path TO Pacilflix;")
            cursor.execute("""DELETE FROM TAYANGAN_TERUNDUH
                           WHERE id_tayangan = %s
                           AND username = %s""", [id_tayangan, username])
        # Setelah berhasil, arahkan kembali ke halaman daftar unduhan
        return redirect('save:detail_favorit')
