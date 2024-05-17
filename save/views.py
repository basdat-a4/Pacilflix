from django.shortcuts import render, redirect
from django.db import connection

def daftar_unduhan(request):
        username = request.COOKIES["username"]
        with connection.cursor() as cursor:
            cursor.execute("""
                            SELECT T.judul, TT.timestamp AS Waktu Diunduh
                            FROM TAYANGAN T
                            INNER JOIN TAYANGAN_TERUNDUH TT ON T.id = TT.id_tayangan;
                            """, [username])
            unduhan_list = cursor.fetchall()
        return render(request, 'daftar_unduhan.html', {'unduhan_list': unduhan_list})


def daftar_favorit(request):
        username = request.COOKIES["username"]
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT judul, timestamp AS Waktu Dibuat
                FROM DAFTAR_FAVORIT
                WHERE username = %s
                """, [username])
            favorit_list = cursor.fetchall()
        return render(request, 'daftar_favorit.html', {'favorit_list': favorit_list})
    

def detail_favorit(request, favorit_id):
        username = request.COOKIES["username"]
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT t.judul, t.id_tayangan
                FROM TAYANGAN t
                JOIN DAFTAR_FAVORIT_DETAIL dfd ON t.id_tayangan = dfd.id_tayangan
                WHERE dfd.id_favorit = %s
                """, [favorit_id])
            tayangan_list = cursor.fetchall()
        return render(request, 'detail_favorit.html', {'tayangan_list': tayangan_list, 'favorit_id': favorit_id, 'user': request.user})
    

# def hapus_favorit(request, favorit_id):
#         username = request.COOKIES["username"]
#         try:
#             with connection.cursor() as cursor:
#                 cursor.execute("""
#                     DELETE FROM DAFTAR_FAVORIT
#                     WHERE id_favorit = %s AND username = %s
#                 """, [favorit_id, username])
#             return JsonResponse({'success': True})
#         except Exception as e:
#             return JsonResponse({'success': False, 'message': str(e)})
