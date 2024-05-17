from django.shortcuts import render
from django.db import connection
from authentication.views import login_required_custom

# Create your views here.
@login_required_custom
def show_contributors(request):
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")
    cursor.execute("""
                    SELECT nama, 
                            'Sutradara' AS tipe, 
                            CASE jenis_kelamin
                                WHEN 1 THEN 'perempuan'
                                WHEN 0 THEN 'laki-laki'
                            END AS jenis_kelamin,
                            kewarganegaraan
                    FROM contributors C JOIN sutradara S ON S.id = C.id
                    UNION
                    SELECT nama, 
                            'Pemain' AS tipe, 
                            CASE jenis_kelamin
                                WHEN 1 THEN 'perempuan'
                                WHEN 0 THEN 'laki-laki'
                            END AS jenis_kelamin,
                            kewarganegaraan
                    FROM contributors C JOIN pemain P ON P.id = C.id
                    UNION
                    SELECT nama, 
                            'Penulis' AS tipe, 
                            CASE jenis_kelamin
                                WHEN 1 THEN 'perempuan'
                                WHEN 0 THEN 'laki-laki'
                            END AS jenis_kelamin,
                            kewarganegaraan
                    FROM contributors C JOIN penulis_skenario P ON P.id = C.id;
                   """)
    rows = cursor.fetchall()

    return render(request, "daftar_kontributor.html", {"rows": rows})

@login_required_custom
def show_sutradara(request):
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")
    cursor.execute("""
                    SELECT nama, 
                            'Sutradara' AS tipe, 
                            CASE jenis_kelamin
                                WHEN 1 THEN 'perempuan'
                                WHEN 0 THEN 'laki-laki'
                            END AS jenis_kelamin,
                            kewarganegaraan
                    FROM contributors C JOIN sutradara S ON S.id = C.id;
                   """)
    rows = cursor.fetchall()

    return render(request, "daftar_kontributor.html", {"rows": rows})

@login_required_custom
def show_pemain(request):
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")
    cursor.execute("""
                    SELECT nama, 
                            'Pemain' AS tipe, 
                            CASE jenis_kelamin
                                WHEN 1 THEN 'perempuan'
                                WHEN 0 THEN 'laki-laki'
                            END AS jenis_kelamin,
                            kewarganegaraan
                    FROM contributors C JOIN pemain P ON P.id = C.id;
                   """)
    rows = cursor.fetchall()

    return render(request, "daftar_kontributor.html", {"rows": rows})

@login_required_custom
def show_penulis(request):
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")
    cursor.execute("""
                    SELECT nama, 
                            'Penulis' AS tipe, 
                            CASE jenis_kelamin
                                WHEN 1 THEN 'perempuan'
                                WHEN 0 THEN 'laki-laki'
                            END AS jenis_kelamin,
                            kewarganegaraan
                    FROM contributors C JOIN penulis_skenario P ON P.id = C.id;
                   """)
    rows = cursor.fetchall()

    return render(request, "daftar_kontributor.html", {"rows": rows})