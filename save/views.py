from datetime import datetime
from pyexpat.errors import messages
from django.shortcuts import render, redirect
from django.db import connection

def daftar_unduhan(request):
        username = request.COOKIES["username"]
        with connection.cursor() as cursor:
            cursor.execute("SET search_path TO Pacilflix;")
            cursor.execute("""
                        SELECT T.judul, TT.timestamp, T.id
                        FROM TAYANGAN T
                        JOIN TAYANGAN_TERUNDUH TT ON T.id = TT.id_tayangan
                        WHERE TT.username = %s;
                        """, [username])
            unduhan_list = cursor.fetchall()
            context = {
                'username': username,
                'unduhan_list': [
                    (unduhan_list[i][0], unduhan_list[i][1], unduhan_list[i][1].isoformat(), unduhan_list[i][2]) for i in range(len(unduhan_list))
                ],
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
                'favorit_list': [
                     {
                          "timestamp": favorit[1],
                          "timestamp_iso": favorit[1].isoformat(),
                          "username": username,
                          "judul": favorit[0],
                     } for favorit in favorit_list
                ]
            }
        return render(request, 'daftar_favorit.html', context)
    

def detail_favorit(request, judul):
        username = request.COOKIES["username"]
        with connection.cursor() as cursor:
            cursor.execute("SET search_path TO Pacilflix;")
            cursor.execute("""
                SELECT DISTINCT T.judul, TMDF.timestamp, T.id
                FROM TAYANGAN_MEMILIKI_DAFTAR_FAVORIT TMDF
                JOIN DAFTAR_FAVORIT DF ON TMDF.username = DF.username
                JOIN TAYANGAN T ON TMDF.id_tayangan = T.id
                WHERE DF.username = %s AND DF.judul = %s
                """, [username, judul])
            tayangan_list = cursor.fetchall()
            context = {
                'username': username,
                'tayangan_list': [
                    (tayangan_list[i][0],tayangan_list[i][1], tayangan_list[i][1].isoformat(), tayangan_list[i][2]) for i in range(len(tayangan_list))                 
                ],
                'playlist_judul': judul
            }
        return render(request, 'detail_favorit.html', context)

# def hapus_unduhan(request):
#     if request.method == 'POST':
#         id_tayangan = request.GET.get('id_tayangan')
#         username = request.COOKIES.get('username')
#         with connection.cursor() as cursor:
#             cursor.execute("SET search_path TO Pacilflix;")
#             cursor.execute("""DELETE FROM TAYANGAN_TERUNDUH
#                            WHERE id_tayangan = %s
#                            AND username = %s""", [id_tayangan, username])
#         # Setelah berhasil, arahkan kembali ke halaman daftar unduhan
#         return redirect('save:detail_favorit')

def hapus_unduhan(request, id_tayangan, timestamp):
    if request.method == 'POST':
        username = request.COOKIES["username"]
        new_timestamp = datetime.strptime(timestamp, "%Y-%m-%dT%H:%M:%S")
        with connection.cursor() as cursor:
            cursor.execute("SET search_path TO Pacilflix;")
            cursor.execute("""
                    DELETE FROM TAYANGAN_TERUNDUH
                    WHERE id_tayangan = %s AND username = %s AND timestamp = %s
                    """, [id_tayangan, username, new_timestamp])
            connection.commit()
        return redirect('/save/unduhan/')
    
def hapus_favorit(request, timestamp):
    if request.method == 'POST':
        username = request.COOKIES["username"]
        new_timestamp = datetime.strptime(timestamp, "%Y-%m-%dT%H:%M:%S")
        with connection.cursor() as cursor:
            cursor.execute("SET search_path TO Pacilflix;")
            cursor.execute("""DELETE FROM TAYANGAN_MEMILIKI_DAFTAR_FAVORIT
                           WHERE username = %s AND timestamp = %s
                           """, [username, new_timestamp])
            cursor.execute("""
                    DELETE FROM DAFTAR_FAVORIT
                    WHERE username = %s AND timestamp = %s
                    """, [username, new_timestamp])
            connection.commit()
        return redirect('/save/favorit')

def hapus_tayangan(request, id_tayangan, timestamp):
    if request.method == 'POST':
        username = request.COOKIES['username']
        new_timestamp = datetime.strptime(timestamp, "%Y-%m-%dT%H:%M:%S")
        with connection.cursor() as cursor:
        # Hapus tayangan dari suatu daftar favorit
            if connection is None or cursor is None:
                messages.error(request, 'Database connection failed')
            else:
                try: 
                    cursor.execute("SET search_path TO Pacilflix;")
                    cursor.execute("""
                            DELETE FROM TAYANGAN_MEMILIKI_DAFTAR_FAVORIT
                            WHERE username = %s AND timestamp = %s AND id_tayangan = %s
                            """, [username, new_timestamp, id_tayangan])
                    connection.commit()
                except Exception as error:
                    messages.error(request, f'Terjadi kesalahan {error}')
                finally:
                    cursor.close()
                    connection.close()
        return redirect('save:daftar_favorit')

