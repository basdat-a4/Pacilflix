from django.http import JsonResponse
from django.shortcuts import render
from django.db import connection

# Create your views here.
def show_trailer(request):
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")
    cursor.execute(""" 
                    WITH durasi_tayangan AS (
                        SELECT
                            id_series AS id_tayangan,
                            SUM(durasi) AS total_durasi
                        FROM
                            EPISODE
                        GROUP BY
                            id_series
                    ),
                    total_viewers AS (
                        SELECT
                            id_tayangan,
                            COUNT(*) AS total_viewer
                        FROM
                            RIWAYAT_NONTON rn
                        WHERE
                            start_date_time >= CURRENT_DATE - INTERVAL '7 days'
                        GROUP BY
                            id_tayangan
                    )
                    SELECT
                        ROW_NUMBER() OVER (ORDER BY COALESCE(tv.total_viewer, 0) DESC, t.judul) AS peringkat,
                        t.judul,
                        t.sinopsis_trailer,
                        t.url_video_trailer,
                        t.release_date_trailer,
                        COALESCE(tv.total_viewer, 0) AS total_view_7_hari_terakhir
                    FROM
                        TAYANGAN t
                    LEFT JOIN
                        total_viewers tv ON t.id = tv.id_tayangan
                    WHERE
                        t.id IN (SELECT id_tayangan FROM durasi_tayangan WHERE total_durasi > 0)
                    ORDER BY
                        total_view_7_hari_terakhir DESC,
                        t.judul
                    LIMIT 10;
                   """)
    rowsTop10 = cursor.fetchall()

    cursor.execute("""
                    SELECT 
                        t.judul,
                        t.sinopsis_trailer,
                        t.url_video_trailer,
                        t.release_date_trailer
                    FROM 
                        TAYANGAN t
                    JOIN 
                        SERIES s ON t.id = s.id_tayangan;
                    """) 
    rowsSeries = cursor.fetchall()

    cursor.execute("""
                    SELECT 
                        t.judul,
                        t.sinopsis_trailer,
                        t.url_video_trailer,
                        t.release_date_trailer
                    FROM 
                        TAYANGAN t
                    JOIN 
                        FILM f ON t.id = f.id_tayangan;
                    """) 
    rowsFilm = cursor.fetchall()

    context = {
        "rowsSeries": rowsSeries,
        "rowsTop10": rowsTop10,
        "rowsFilm" : rowsFilm,
        'username': request.COOKIES.get('username')
    }
    return render(request, "trailer.html", context)

def show_tayangan(request):
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")

    cursor.execute(""" 
                    WITH durasi_tayangan AS (
                        SELECT
                            id_series AS id_tayangan,
                            SUM(durasi) AS total_durasi
                        FROM
                            EPISODE
                        GROUP BY
                            id_series
                    ),
                    total_viewers AS (
                        SELECT
                            id_tayangan,
                            COUNT(*) AS total_viewer
                        FROM
                            RIWAYAT_NONTON rn
                        WHERE
                            start_date_time >= CURRENT_DATE - INTERVAL '7 days'
                        GROUP BY
                            id_tayangan
                    )
                    SELECT
                        ROW_NUMBER() OVER (ORDER BY COALESCE(tv.total_viewer, 0) DESC, t.judul) AS peringkat,
                        t.judul,
                        t.sinopsis_trailer,
                        t.url_video_trailer,
                        t.release_date_trailer,
                        COALESCE(tv.total_viewer, 0) AS total_view_7_hari_terakhir
                    FROM
                        TAYANGAN t
                    LEFT JOIN
                        total_viewers tv ON t.id = tv.id_tayangan
                    WHERE
                        t.id IN (SELECT id_tayangan FROM durasi_tayangan WHERE total_durasi > 0)
                    ORDER BY
                        total_view_7_hari_terakhir DESC,
                        t.judul
                    LIMIT 10;
                   """)
    rowsTop10 = cursor.fetchall()

    cursor.execute("""
                    SELECT 
                        t.judul,
                        t.sinopsis_trailer,
                        t.url_video_trailer,
                        t.release_date_trailer,
                        t.id
                    FROM 
                        TAYANGAN t
                    JOIN 
                        SERIES s ON t.id = s.id_tayangan;
                    """) 
    rowsSeries = cursor.fetchall()

    cursor.execute("""
                    SELECT 
                        t.judul,
                        t.sinopsis_trailer,
                        t.url_video_trailer,
                        t.release_date_trailer, 
                        t.id
                    FROM 
                        TAYANGAN t
                    JOIN 
                        FILM f ON t.id = f.id_tayangan;
                    """) 
    rowsFilm = cursor.fetchall()

    user = request.COOKIES['username']

    cursor.execute("""
                    SELECT t.username 
                    FROM TRANSACTION t 
                    WHERE %s = t.username 
                        AND t.end_date_time >= CURRENT_DATE;
                    """, [user])
    paketAktif = cursor.fetchall()

    context = {
        "rowsSeries": rowsSeries,
        "rowsTop10": rowsTop10,
        "rowsFilm" : rowsFilm,
        "paketAktif" : paketAktif,
        'username': user
    }
    return render(request, "tayangan.html", context)

def show_film(request, id):
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")

    cursor.execute("""
                SELECT f.id_tayangan, t.judul, t.sinopsis, f.durasi_film, f.release_date_film, f.url_video_film, t.asal_negara
                FROM FILM f
                JOIN TAYANGAN t ON f.id_tayangan = t.id
                WHERE f.id_tayangan = %s;
                    """, [id])
    dataFilm = cursor.fetchone()

    cursor.execute("""
                    SELECT ROUND(AVG(rating), 1) AS rata_rata_rating
                    FROM ULASAN
                    WHERE id_tayangan = %s;
                """, [id])
    avgRating = cursor.fetchone()

    cursor.execute("""
                    SELECT genre
                    FROM GENRE_TAYANGAN
                    WHERE id_tayangan = %s;
                """, [id])
    genre = cursor.fetchall()

    cursor.execute("""
                    SELECT c.nama
                    FROM CONTRIBUTORS c
                    JOIN MEMAINKAN_TAYANGAN m ON c.id = m.id_pemain
                    WHERE m.id_tayangan = %s;
                """, [id])
    pemain = cursor.fetchall()

    cursor.execute("""
                    SELECT c.nama
                    FROM CONTRIBUTORS c
                    JOIN MENULIS_SKENARIO_TAYANGAN m ON c.id = m.id_penulis_skenario
                    WHERE m.id_tayangan = %s;
                """, [id])
    penulis = cursor.fetchall()

    cursor.execute("""
                    SELECT c.nama
                    FROM CONTRIBUTORS c
                    JOIN TAYANGAN t ON c.id = t.id_sutradara
                    WHERE t.id = %s;
                """, [id])
    sutradara = cursor.fetchone()

    cursor.execute("""
                    SELECT username, deskripsi, rating
                    FROM ULASAN
                    WHERE id_tayangan = %s
                    ORDER BY timestamp DESC;
                """, [id])
    ulasan = cursor.fetchall()

    context = {
        'username': request.COOKIES.get('username'),
        "id" : id,
        "avgRating" : avgRating,
        "genre": genre,
        "pemain": pemain,
        "penulis": penulis,
        "sutradara": sutradara,
        "ulasan": ulasan,
        "dataFilm": dataFilm
    }
    return render(request, "film.html", context)

def show_series(request, id):
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")

    cursor.execute("""
                    SELECT s.id_tayangan, t.judul, t.sinopsis, t.asal_negara
                    FROM SERIES s
                    JOIN TAYANGAN t ON s.id_tayangan = t.id
                    WHERE s.id_tayangan = %s;
                    """, [id])
    dataSeries = cursor.fetchone()

    cursor.execute("""
                    SELECT ROUND(AVG(rating), 1) AS rata_rata_rating
                    FROM ULASAN
                    WHERE id_tayangan = %s;
                """, [id])
    avgRating = cursor.fetchone()

    cursor.execute("""
                    SELECT genre
                    FROM GENRE_TAYANGAN
                    WHERE id_tayangan = %s;
                """, [id])
    genre = cursor.fetchall()

    cursor.execute("""
                    SELECT c.nama
                    FROM CONTRIBUTORS c
                    JOIN MEMAINKAN_TAYANGAN m ON c.id = m.id_pemain
                    WHERE m.id_tayangan = %s;
                """, [id])
    pemain = cursor.fetchall()

    cursor.execute("""
                    SELECT c.nama
                    FROM CONTRIBUTORS c
                    JOIN MENULIS_SKENARIO_TAYANGAN m ON c.id = m.id_penulis_skenario
                    WHERE m.id_tayangan = %s;
                """, [id])
    penulis = cursor.fetchall()

    cursor.execute("""
                    SELECT c.nama
                    FROM CONTRIBUTORS c
                    JOIN TAYANGAN t ON c.id = t.id_sutradara
                    WHERE t.id = %s;
                """, [id])
    sutradara = cursor.fetchone()

    cursor.execute("""
                    SELECT username, deskripsi, rating
                    FROM ULASAN
                    WHERE id_tayangan = %s
                    ORDER BY timestamp DESC;
                """, [id])
    ulasan = cursor.fetchall()

    cursor.execute("""
                    SELECT url_video, sub_judul
                    FROM EPISODE
                    WHERE id_series = %s;
                """, [id])
    episode = cursor.fetchall()

    context = {
        'username': request.COOKIES.get('username'),
        "id" : id,
        "avgRating" : avgRating,
        "genre": genre,
        "pemain": pemain,
        "penulis": penulis,
        "sutradara": sutradara,
        "ulasan": ulasan,
        "dataSeries": dataSeries,
        "episode": episode
    }
    return render(request, "series.html", context)

def show_episode(request, id, subjudul):
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")

    cursor.execute("""
                    SELECT sinopsis, durasi, url_video, release_date
                    FROM EPISODE
                    WHERE id_series = %s AND sub_judul = %s;
                    """, [id, subjudul])
    dataEpisode = cursor.fetchone()

    cursor.execute("""
                    SELECT judul
                    FROM TAYANGAN
                    WHERE id = %s;
                    """, [id])
    judul = cursor.fetchone()

    cursor.execute("""
                    SELECT url_video, sub_judul
                    FROM EPISODE
                    WHERE id_series = %s AND sub_judul != %s;
                """, [id, subjudul])
    episode = cursor.fetchall()

    context = {
        'username': request.COOKIES.get('username'),
        "id" : id,
        "subjudul" : subjudul,
        "dataEpisode": dataEpisode,
        "judul" : judul,
        "episode": episode
    }
    return render(request, "episode.html", context)

def search_tayangan(request):
    if request.method == 'GET' and 'searchInput' in request.GET:
        search_input = request.GET.get('searchInput')

        cursor = connection.cursor()
        cursor.execute("SET search_path TO pacilflix;")

        cursor.execute("""
                        SELECT
                            t.judul,
                            t.sinopsis_trailer,
                            t.url_video_trailer,
                            t.release_date_trailer,
                            t.id
                        FROM
                            TAYANGAN t
                        WHERE
                            t.judul ILIKE %s
                        """, ['%' + search_input + '%'])
        search_results = cursor.fetchall()

    
        search_results_list = []
        for result in search_results:
            id = result[4]
            cursor.execute("""
                    SELECT f.id_tayangan 
                    FROM FILM f
                    WHERE %s = f.id_tayangan;
                    """, [str(id)])
            isFilm = cursor.fetchone()
            search_results_list.append({
                'judul': result[0],
                'sinopsis_trailer': result[1],
                'url_video_trailer': result[2],
                'release_date_trailer': result[3],
                'id': result[4],
                'isFilm' : isFilm
            })

        return JsonResponse(search_results_list, safe=False)
    else:
        return JsonResponse([], safe=False)
    
def search_trailer(request):
    if request.method == 'GET' and 'searchInput' in request.GET:
        search_input = request.GET.get('searchInput')

        cursor = connection.cursor()
        cursor.execute("SET search_path TO pacilflix;")

        cursor.execute("""
                        SELECT
                            t.judul,
                            t.sinopsis_trailer,
                            t.url_video_trailer,
                            t.release_date_trailer
                        FROM
                            TAYANGAN t
                        WHERE
                            t.judul ILIKE %s
                        """, ['%' + search_input + '%'])
        search_results = cursor.fetchall()

    
        search_results_list = []
        for result in search_results:
            search_results_list.append({
                'judul': result[0],
                'sinopsis_trailer': result[1],
                'url_video_trailer': result[2],
                'release_date_trailer': result[3],
            })

        return JsonResponse(search_results_list, safe=False)
    else:
        return JsonResponse([], safe=False)