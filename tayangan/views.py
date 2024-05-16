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
        "rowsFilm" : rowsFilm
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

    dummy_user = "mason_choi"
    cursor.execute("""
                    SELECT t.username 
                    FROM TRANSACTION t 
                    WHERE %s = t.username 
                        AND t.end_date_time >= CURRENT_DATE;
                    """, [dummy_user])
    paketAktif = cursor.fetchall()

    context = {
        "rowsSeries": rowsSeries,
        "rowsTop10": rowsTop10,
        "rowsFilm" : rowsFilm,
        "paketAktif" : paketAktif
    }
    return render(request, "tayangan.html", context)

def show_film(request, id):
    context = {"id" : id}
    return render(request, "film.html", context)

def show_series(request, id):
    context = {"id" : id}
    return render(request, "series.html", context)

def show_episode(request):
    return render(request, "episode.html")