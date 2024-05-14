from django.shortcuts import redirect, render
from django.db import connection

# Create your views here.
def show_langganan(request):
    dummy_user = "mason_choi"

    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")

    cursor.execute("""
    SELECT P.nama, P.harga, P.resolusi_layar, STRING_AGG(D.dukungan_perangkat, ', ') AS dukungan_perangkat
    FROM PAKET P JOIN DUKUNGAN_PERANGKAT D ON D.nama_paket = P.nama
    GROUP BY P.nama, P.harga, P.resolusi_layar;                
    """)
    paket = cursor.fetchall()

    cursor.execute("""
    SELECT T.nama_paket, T.start_date_time, T.end_date_time, T.metode_pembayaran, T.timestamp_pembayaran, P.harga
    FROM TRANSACTION T JOIN PAKET P ON P.nama = T.nama_paket
    WHERE T.username = %s;
    """, [dummy_user])
    transaksi = cursor.fetchall()

    cursor.execute("""
    SELECT T.nama_paket, P.harga, P.resolusi_layar, STRING_AGG(D.dukungan_perangkat, ', '), T.start_date_time, T.end_date_time
    FROM TRANSACTION T JOIN PAKET P ON P.nama = T.nama_paket JOIN DUKUNGAN_PERANGKAT D ON D.nama_paket = P.nama
    WHERE T.username = %s AND CURRENT_DATE BETWEEN T.start_date_time AND T.end_date_time
    GROUP BY T.nama_paket, P.harga, P.resolusi_layar, T.start_date_time, T.end_date_time;
    """, [dummy_user])
    paket_aktif = cursor.fetchone()

    if paket_aktif is None:
        nama = "-"
        harga = "-"
        resolusi = "-"
        perangkat = "-"
        mulai = "-"
        akhir = "-"
    else:
        nama = paket_aktif[0]
        harga = paket_aktif[1]
        resolusi = paket_aktif[2]
        perangkat = paket_aktif[3]
        mulai = paket_aktif[4]
        akhir = paket_aktif[5]

    context = {
        "paket":paket, 
        "transaksi":transaksi, 
        "nama":nama,
        "harga":harga,
        "resolusi":resolusi,
        "perangkat":perangkat,
        "mulai":mulai,
        "akhir":akhir
    }
    
    return render(request, "kelola_langganan.html", context)

def show_beli(request, paket):
    if request.method == 'POST':
        metode_pembayaran = request.POST.get('pay')

        dummy_user = "mason_choi"
        
        cursor = connection.cursor()
        cursor.execute("SET search_path TO pacilflix;")

        cursor.execute("INSERT INTO TRANSACTION VALUES(%s, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 MONTH', %s, %s, CURRENT_TIMESTAMP)", [dummy_user, paket, metode_pembayaran])
        return redirect('langganan:show_langganan')
    
    cursor = connection.cursor()
    cursor.execute("SET search_path TO pacilflix;")

    cursor.execute("""
    SELECT P.nama, P.harga, P.resolusi_layar, STRING_AGG(D.dukungan_perangkat, ', ') AS dukungan_perangkat
    FROM PAKET P JOIN DUKUNGAN_PERANGKAT D ON D.nama_paket = P.nama
    WHERE P.nama = %s
    GROUP BY P.nama, P.harga, P.resolusi_layar;
                   """, [paket])
    paket = cursor.fetchone()

    return render(request, "beli_langganan.html", {"paket":paket})

# def beli_paket(request, paket):
#     if request.method == 'POST':
#         metode_pembayaran = request.POST.get('pay')

#         dummy_user = "mason_choi"
        
#         cursor = connection.cursor()
#         cursor.execute("SET search_path TO pacilflix;")

#         cursor.execute("INSERT INTO TRANSACTION VALUES(%s, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 MONTH', %s, %s, CURRENT_TIMESTAMP)", [dummy_user, paket, metode_pembayaran])
#         return redirect('langganan:show_langganan')