from datetime import datetime, timedelta
import math
from django.http import JsonResponse
from django.shortcuts import render
from django.db import connection
from authentication.views import login_required_custom
from django.views.decorators.csrf import csrf_exempt

@login_required_custom
def show_trailer(request):
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")
    cursor.execute(""" 
                    WITH viewer_count AS (
                        SELECT rn.id_tayangan,
                            COUNT(*) AS total_view
                        FROM RIWAYAT_NONTON AS rn
                        LEFT JOIN FILM AS f ON rn.id_tayangan = f.id_tayangan
                        LEFT JOIN EPISODE AS e ON rn.id_tayangan = e.id_series
                        WHERE rn.end_date_time >= NOW() - INTERVAL '7 days'
                        AND EXTRACT(EPOCH FROM (rn.end_date_time - rn.start_date_time)) / 60 >= 0.7 * COALESCE(f.durasi_film, e.durasi)
                        GROUP BY rn.id_tayangan
                    ),
                    ranked_viewers AS (
                        SELECT id_tayangan,
                            COALESCE(total_view, 0) AS total_view,
                            ROW_NUMBER() OVER (ORDER BY COALESCE(total_view, 0) DESC) AS rank
                        FROM viewer_count
                    )
                    SELECT
                    t.id,  
                    t.judul, 
                    t.sinopsis_trailer, 
                    t.url_video_trailer,
                    t.release_date_trailer,
                    COALESCE(total_view, 0) as total_view,
                    CASE WHEN rv.total_view = 0 THEN ROW_NUMBER() OVER (ORDER BY t.judul)
                        ELSE rv.rank
                    END AS rank
                    FROM TAYANGAN AS t 
                    LEFT JOIN ranked_viewers AS rv ON t.id = rv.id_tayangan
                    ORDER BY rank
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

@login_required_custom
def show_tayangan(request):
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")

    cursor.execute(""" 
                    WITH viewer_count AS (
                        SELECT rn.id_tayangan,
                            COUNT(*) AS total_view
                        FROM RIWAYAT_NONTON AS rn
                        LEFT JOIN FILM AS f ON rn.id_tayangan = f.id_tayangan
                        LEFT JOIN EPISODE AS e ON rn.id_tayangan = e.id_series
                        WHERE rn.end_date_time >= NOW() - INTERVAL '7 days'
                        AND EXTRACT(EPOCH FROM (rn.end_date_time - rn.start_date_time)) / 60 >= 0.7 * COALESCE(f.durasi_film, e.durasi)
                        GROUP BY rn.id_tayangan
                    ),
                    ranked_viewers AS (
                        SELECT id_tayangan,
                            COALESCE(total_view, 0) AS total_view,
                            ROW_NUMBER() OVER (ORDER BY COALESCE(total_view, 0) DESC) AS rank
                        FROM viewer_count
                    )
                    SELECT
                    t.id,  
                    t.judul, 
                    t.sinopsis_trailer, 
                    t.url_video_trailer,
                    t.release_date_trailer,
                    COALESCE(total_view, 0) as total_view,
                    CASE 
                        WHEN EXISTS (SELECT 1 FROM FILM f WHERE f.id_tayangan = t.id) THEN 'Film'
                        WHEN EXISTS (SELECT 1 FROM SERIES s WHERE s.id_tayangan = t.id) THEN 'Series'
                        ELSE 'Unknown'
                    END AS type,
                    CASE WHEN rv.total_view = 0 THEN ROW_NUMBER() OVER (ORDER BY t.judul)
                        ELSE rv.rank
                    END AS rank
                    FROM TAYANGAN AS t 
                    LEFT JOIN ranked_viewers AS rv ON t.id = rv.id_tayangan
                    ORDER BY rank
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

@login_required_custom
def show_film(request, id):
    user = request.COOKIES['username']
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

    cursor.execute("""
                    SELECT rn.id_tayangan,
                    COUNT(*) AS total_view
                    FROM RIWAYAT_NONTON AS rn
                    LEFT JOIN FILM AS f ON rn.id_tayangan = f.id_tayangan
                    JOIN TAYANGAN AS t ON rn.id_tayangan = t.id
                    WHERE t.id = %s
                    AND EXTRACT(EPOCH FROM (rn.end_date_time - rn.start_date_time)) / 60 >= 0.7 * COALESCE(f.durasi_film, 0)
                    GROUP BY rn.id_tayangan;
                    """, [str(id)])
    viewers = cursor.fetchone()

    cursor.execute("""
                    SELECT f.id_tayangan 
                    FROM FILM f
                    WHERE %s = f.id_tayangan 
                        AND f.release_date_film <= CURRENT_DATE;
                    """, [str(id)])
    isRelease = cursor.fetchall()

    cursor.execute("""
                    SELECT df.timestamp, df.judul
                    FROM DAFTAR_FAVORIT AS df
                    WHERE %s = df.username;
                    """, [str(user)])
    daftarFavorit = cursor.fetchall()

    context = {
        'username': request.COOKIES.get('username'),
        "id" : id,
        "avgRating" : avgRating,
        "genre": genre,
        "pemain": pemain,
        "penulis": penulis,
        "sutradara": sutradara,
        "ulasan": ulasan,
        "dataFilm": dataFilm,
        "viewers": viewers,
        "isRelease": isRelease,
        "daftarFavorit": daftarFavorit
    }
    return render(request, "film.html", context)

@login_required_custom
def show_series(request, id):
    user = request.COOKIES['username']
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

    cursor.execute("""
                    WITH episode_durations AS (
                    SELECT id_series,
                    SUM(durasi) AS total_durasi
                    FROM EPISODE
                    GROUP BY id_series
                    )
                    SELECT rn.id_tayangan,
                    COUNT(*) AS total_view
                    FROM RIWAYAT_NONTON AS rn
                    LEFT JOIN FILM AS f ON rn.id_tayangan = f.id_tayangan
                    LEFT JOIN episode_durations AS ed ON rn.id_tayangan = ed.id_series
                    JOIN TAYANGAN AS t ON rn.id_tayangan = t.id
                    WHERE t.id = %s
                    AND EXTRACT(EPOCH FROM (rn.end_date_time - rn.start_date_time)) / 60 >= 0.7 * COALESCE(f.durasi_film, ed.total_durasi)
                    GROUP BY rn.id_tayangan
                    """, [str(id)])
    viewers = cursor.fetchone()

    cursor.execute("""
                    SELECT df.timestamp, df.judul
                    FROM DAFTAR_FAVORIT AS df
                    WHERE %s = df.username;
                    """, [str(user)])
    daftarFavorit = cursor.fetchall()

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
        "episode": episode,
        "viewers": viewers,
        "daftarFavorit": daftarFavorit
    }
    return render(request, "series.html", context)

@login_required_custom
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

    cursor.execute("""
                    SELECT e.id_series
                    FROM EPISODE e
                    WHERE %s = e.id_series AND %s = e.sub_judul 
                        AND f.release_date_film <= CURRENT_DATE;
                    """, [str(id), str(subjudul)])
    isRelease = cursor.fetchall()

    context = {
        'username': request.COOKIES.get('username'),
        "id" : id,
        "subjudul" : subjudul,
        "dataEpisode": dataEpisode,
        "judul" : judul,
        "episode": episode,
        "isRelease": isRelease
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
    
def get_reviews(request):
    id = request.GET.get('id')
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")

    cursor.execute("""
                    SELECT username, deskripsi, rating
                    FROM ULASAN
                    WHERE id_tayangan = %s
                    ORDER BY timestamp DESC;
                """, [str(id)])
    ulasan = cursor.fetchall()

    reviews_data = []
    for review in ulasan:
        review_data = {
            'username': review[0],
            'deskripsi': review[1],
            'rating': review[2]
        }
        reviews_data.append(review_data)

    return JsonResponse(reviews_data, safe=False)

@csrf_exempt
def submit_review(request):
    if request.method == 'POST':
        # Ambil data dari permintaan AJAX
        id = request.GET.get('id')
        deskripsi = request.GET.get("deskripsi")
        rating = request.GET.get("rating")
        username = request.COOKIES.get('username')

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cursor = connection.cursor()
        cursor.execute("SET search_path TO pacilflix;")
        cursor.execute("""
                        INSERT INTO ULASAN VALUES (%s, %s, %s, %s, %s);
                        """, [id, username, timestamp, rating, deskripsi])

        # Kirim respons JSON kembali ke front end
        return JsonResponse({'status': 'success'})
    else:
        return JsonResponse({'status': 'error', 'message': 'Invalid request method'})
    
@csrf_exempt
def tambah_unduhan(request):
    id = request.GET.get('id')
    username = request.COOKIES.get('username')
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")

    cursor.execute("""
    INSERT INTO TAYANGAN_TERUNDUH VALUES (%s, %s, %s);
                """, [id, username, timestamp])
    return JsonResponse({'status': 'success'})

@csrf_exempt
def tonton(request):
    id = request.GET.get('id')
    durasi = request.GET.get('durasi')
    username = request.COOKIES.get('username')
    subjudul = request.GET.get('subjudul')
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")

    if subjudul=="":
        cursor.execute("""
            SELECT f.durasi_film 
            FROM FILM f
            WHERE f.id_tayangan = %s;
        """, [str(id)])
        film = cursor.fetchone()
        durasiAsli = film[0]
    else:
        cursor.execute("""
            SELECT e.durasi 
            FROM EPISODE e
            WHERE e.id_series = %s AND e.sub_judul = %s;
        """, [str(id), str(subjudul)])
        episode = cursor.fetchone()
        durasiAsli = episode[0]

    # Menghitung timestamp sekarang dan timestamp setelah menonton
    timestampNow = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    durasi_nonton = (int(durasi) / 100) * durasiAsli
    # durasi_nonton = math.ceil((int(durasi) / 100) * durasi_asli)
    timestampAfter = (datetime.now() + timedelta(minutes=durasi_nonton)).strftime("%Y-%m-%d %H:%M:%S")

    cursor.execute("""
                    INSERT INTO RIWAYAT_NONTON VALUES (%s, %s, %s, %s);
                    """, [id, username, timestampNow, timestampAfter])
    
    return JsonResponse({'status': 'success'})

@csrf_exempt
def favorit(request):
    id = request.GET.get('id')
    # timestampStr = request.GET.get('timestamp')
    # timestamp = timestampStr.replace('a.m.', 'am').replace('p.m.', 'pm')

    timestampStr = request.GET.get('timestamp')

    # Ubah format "pm" dan "am" agar sesuai dengan format yang diharapkan
    timestampStr = timestampStr.replace('a.m.', 'am').replace('p.m.', 'pm')

    # Coba format tanggal untuk format pertama
    try:
        timestampPre = datetime.strptime(timestampStr, "%b. %d, %Y, %I:%M %p")
    except ValueError:
        # Jika format pertama gagal, coba format kedua
        try:
            timestampPre = datetime.strptime(timestampStr, "%B %d, %Y, %I:%M %p")
        except ValueError:
            # Jika kedua format gagal, lemparkan ValueError
            raise ValueError("Invalid date format")

    # # Hapus titik setelah nama bulan
    # timestampStr = timestampStr.replace(".", "")

    # Format the datetime object as needed (optional)
    # timestamp = timestampPre.strftime("%Y-%m-%d %H:%M:%S")

    username = request.COOKIES.get('username')

    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")

    cursor.execute("""
                    INSERT INTO TAYANGAN_MEMILIKI_DAFTAR_FAVORIT VALUES (%s, %s, %s);
                    """, [id, timestampPre, username])
    
    return JsonResponse({'status': 'success'})