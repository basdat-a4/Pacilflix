CREATE SCHEMA PACILFLIX;

SET search_path TO PACILFLIX;

CREATE TABLE PAKET (
    nama VARCHAR(50) PRIMARY KEY,
    harga INTEGER NOT NULL CHECK (harga >= 0),
    resolusi_layar VARCHAR(50) NOT NULL
);

CREATE TABLE CONTRIBUTORS (
    id UUID PRIMARY KEY,
    nama VARCHAR(50) NOT NULL,
    jenis_kelamin INTEGER NOT NULL CHECK (jenis_kelamin IN (0, 1)),
    kewarganegaraan VARCHAR(50) NOT NULL
);

CREATE TABLE PENULIS_SKENARIO (
    id UUID PRIMARY KEY,
    FOREIGN KEY (id) REFERENCES CONTRIBUTORS (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE PEMAIN (
    id UUID PRIMARY KEY,
    FOREIGN KEY (id) REFERENCES CONTRIBUTORS (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE SUTRADARA (
    id UUID PRIMARY KEY,
    FOREIGN KEY (id) REFERENCES CONTRIBUTORS (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE TAYANGAN (
    id UUID PRIMARY KEY,
    judul VARCHAR(100) NOT NULL,
    sinopsis VARCHAR(255) NOT NULL,
    asal_negara VARCHAR(50) NOT NULL,
    sinopsis_trailer VARCHAR(255) NOT NULL,
    url_video_trailer VARCHAR(255) NOT NULL,
    release_date_trailer DATE NOT NULL,
    id_sutradara UUID,
    FOREIGN KEY (id_sutradara) REFERENCES SUTRADARA (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE PENGGUNA (
    username VARCHAR(50) PRIMARY KEY,
    PASSWORD VARCHAR(50) NOT NULL,
    negara_asal VARCHAR(50) NOT NULL
);

CREATE TABLE DUKUNGAN_PERANGKAT (
    nama_paket VARCHAR(50),
    dukungan_perangkat VARCHAR(50),
    PRIMARY KEY (
        nama_paket,
        dukungan_perangkat
    ),
    FOREIGN KEY (nama_paket) REFERENCES PAKET (nama) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE TRANSACTION (
    username VARCHAR(50),
    start_date_time DATE,
    end_date_time DATE,
    nama_paket VARCHAR(50),
    metode_pembayaran VARCHAR(50) NOT NULL,
    timestamp_pembayaran TIMESTAMP NOT NULL,
    PRIMARY KEY (username, start_date_time),
    FOREIGN KEY (username) REFERENCES PENGGUNA (username) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (nama_paket) REFERENCES PAKET (nama) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE MEMAINKAN_TAYANGAN (
    id_tayangan UUID,
    id_pemain UUID,
    PRIMARY KEY (id_tayangan, id_pemain),
    FOREIGN KEY (id_tayangan) REFERENCES TAYANGAN (id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_pemain) REFERENCES PEMAIN (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE MENULIS_SKENARIO_TAYANGAN (
    id_tayangan UUID,
    id_penulis_skenario UUID,
    PRIMARY KEY (
        id_tayangan,
        id_penulis_skenario
    ),
    FOREIGN KEY (id_tayangan) REFERENCES TAYANGAN (id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (id_penulis_skenario) REFERENCES PENULIS_SKENARIO (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE GENRE_TAYANGAN (
    id_tayangan UUID,
    genre VARCHAR(50),
    PRIMARY KEY (id_tayangan, genre),
    FOREIGN KEY (id_tayangan) REFERENCES TAYANGAN (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE PERUSAHAAN_PRODUKSI (nama VARCHAR(100) PRIMARY KEY);

CREATE TABLE PERSETUJUAN (
    nama VARCHAR(100),
    id_tayangan UUID,
    tanggal_persetujuan DATE,
    durasi INT NOT NULL CHECK (durasi >= 0),
    biaya INT NOT NULL CHECK (biaya >= 0),
    tanggal_mulai_penayangan DATE NOT NULL,
    PRIMARY KEY (
        nama,
        id_tayangan,
        tanggal_persetujuan
    ),
    FOREIGN KEY (nama) REFERENCES PERUSAHAAN_PRODUKSI (nama) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_tayangan) REFERENCES TAYANGAN (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE SERIES (
    id_tayangan UUID PRIMARY KEY,
    FOREIGN KEY (id_tayangan) REFERENCES TAYANGAN (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE FILM (
    id_tayangan UUID PRIMARY KEY,
    url_video_film VARCHAR(255) NOT NULL,
    release_date_film DATE NOT NULL,
    durasi_film INT NOT NULL DEFAULT 0,
    FOREIGN KEY (id_tayangan) REFERENCES TAYANGAN (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE EPISODE (
    id_series UUID,
    sub_judul VARCHAR(100),
    sinopsis VARCHAR(255) NOT NULL,
    durasi INT NOT NULL DEFAULT 0,
    url_video VARCHAR(255) NOT NULL,
    release_date DATE NOT NULL,
    PRIMARY KEY (id_series, sub_judul),
    FOREIGN KEY (id_series) REFERENCES SERIES (id_tayangan) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE ULASAN (
    id_tayangan UUID,
    username VARCHAR(50),
    TIMESTAMP TIMESTAMP,
    rating INT NOT NULL DEFAULT 0,
    deskripsi VARCHAR(255),
    PRIMARY KEY (username, TIMESTAMP),
    FOREIGN KEY (id_tayangan) REFERENCES TAYANGAN (id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (username) REFERENCES PENGGUNA (username) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE DAFTAR_FAVORIT (
    TIMESTAMP TIMESTAMP,
    username VARCHAR(50),
    judul VARCHAR(50) NOT NULL,
    PRIMARY KEY (TIMESTAMP, username),
    FOREIGN KEY (username) REFERENCES PENGGUNA (username) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE TAYANGAN_MEMILIKI_DAFTAR_FAVORIT (
    id_tayangan UUID,
    TIMESTAMP TIMESTAMP,
    username VARCHAR(50),
    PRIMARY KEY (
        id_tayangan,
        TIMESTAMP,
        username
    ),
    FOREIGN KEY (id_tayangan) REFERENCES TAYANGAN (id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (TIMESTAMP, username) REFERENCES DAFTAR_FAVORIT (TIMESTAMP, username) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE RIWAYAT_NONTON (
    id_tayangan UUID,
    username VARCHAR(50),
    start_date_time TIMESTAMP,
    end_date_time TIMESTAMP NOT NULL,
    PRIMARY KEY (username, start_date_time),
    FOREIGN KEY (id_tayangan) REFERENCES TAYANGAN (id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (username) REFERENCES PENGGUNA (username) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE TAYANGAN_TERUNDUH (
    id_tayangan UUID,
    username VARCHAR(50),
    TIMESTAMP TIMESTAMP,
    PRIMARY KEY (
        id_tayangan,
        username,
        TIMESTAMP
    ),
    FOREIGN KEY (id_tayangan) REFERENCES TAYANGAN (id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (username) REFERENCES PENGGUNA (username) ON UPDATE CASCADE ON DELETE CASCADE
);
-- CEK HAPUS UNDUHAN
CREATE OR REPLACE FUNCTION cek_unduhan_before_delete()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.timestamp < NOW() - INTERVAL '1 day' THEN
        RETURN OLD;
    ELSE
        RAISE EXCEPTION 'Tayangan tidak dapat dihapus karena belum terunduh selama lebih dari 1 hari';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_delete_unduhan BEFORE DELETE ON TAYANGAN_TERUNDUH FOR EACH ROW
EXECUTE FUNCTION cek_unduhan_before_delete ();

-- CEK USERNAME ADA/TIDAK
CREATE OR REPLACE FUNCTION check_exist_username()
RETURNS TRIGGER AS $$
BEGIN
    -- Mengecek apakah username sudah ada di tabel PENGGUNA
    IF EXISTS (SELECT 1 FROM PENGGUNA WHERE username = NEW.username) THEN
        RAISE EXCEPTION 'Username % sudah terdaftar.', NEW.username;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_exist_username
BEFORE INSERT ON PENGGUNA
FOR EACH ROW
EXECUTE FUNCTION check_exist_username();

-- CEK PAKET ADA/TIDAK
CREATE OR REPLACE FUNCTION check_paket_exist() RETURNS TRIGGER AS 
$$
	DECLARE
		paket_exist BOOLEAN;
	BEGIN 
		SELECT EXISTS(
			SELECT 1
			FROM TRANSACTION
			WHERE username = NEW.username AND NEW.start_date_time BETWEEN start_date_time AND end_date_time
		) INTO paket_exist;

		IF paket_exist THEN
			UPDATE TRANSACTION
			SET start_date_time = NEW.start_date_time,
				end_date_time = NEW.end_date_time,
				nama_paket = NEW.nama_paket,
				metode_pembayaran = NEW.metode_pembayaran,
				timestamp_pembayaran = NEW.timestamp_pembayaran
			WHERE username = NEW.username AND start_date_time = NEW.start_date_time;
			RETURN NULL;
		ELSE
			RETURN NEW;
		END IF;
	END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER beli_paket
BEFORE INSERT ON TRANSACTION
FOR EACH ROW
EXECUTE FUNCTION check_paket_exist();

CREATE OR REPLACE FUNCTION check_existing_review() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM ulasan WHERE id_tayangan = NEW.id_tayangan AND username = NEW.username) THEN
        RAISE EXCEPTION 'User has already submitted a review for this title';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_duplicate_review
BEFORE INSERT ON ulasan
FOR EACH ROW
EXECUTE FUNCTION check_existing_review();

INSERT INTO
    PAKET
VALUES ('Basic', 10.0, 'HD'),
    ('Standard', 15.0, 'Full HD'),
    ('Premium', 20.0, 'Ultra HD');

INSERT INTO
    CONTRIBUTORS
VALUES (
        '343a2916-a547-4917-af69-f9305a118854',
        'Jon Stark',
        0.0,
        'USA'
    ),
    (
        '0c1d2e3f-4a5b-6c7d-8e9f-0a1b2c3d4e5f',
        'Sansa Eyrie',
        1.0,
        'Canada'
    ),
    (
        '0e1f2a3b-4c5d-6e7f-8a9b-0c1d2e3f4a5b',
        'Sam Smith',
        0.0,
        'UK'
    ),
    (
        '0f1a2b3c-8d9e-0f1a-2b3c-4d5e6f7a8b9e',
        'Michelle Liau',
        1.0,
        'Australia'
    ),
    (
        '11299894-832d-417a-a347-82176e700746',
        'Robert Green',
        0.0,
        'Germany'
    ),
    (
        '1a2b3c4d-9e0f-1a2b-3c4d-5e6f7a8b9e0f',
        'Arya Brown',
        1.0,
        'Japan'
    ),
    (
        '1a3c6f7d-8b9e-4f0a-9b1c-2d3e4f5a6b7c',
        'Andrew Scott',
        0.0,
        'Brazil'
    ),
    (
        '1b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e',
        'Blake Christie',
        1.0,
        'France'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        'Indira Thorpe',
        1.0,
        'Italy'
    ),
    (
        'a43d6971-04d3-46d5-8229-4bbbde4f0f78',
        'John Doe',
        1.0,
        'USA'
    ),
    (
        '25e223f4-428a-4616-927c-6061d1923614',
        'Jane Smith',
        0.0,
        'Canada'
    ),
    (
        '2a3b4c5d-6e7f-8a9b-0c1d-2e3f4a5b6c7d',
        'Michael Johnson',
        1.0,
        'UK'
    ),
    (
        'f38fe383-8e1c-4203-af26-4c8d92f012b6',
        'Emily Brown',
        0.0,
        'Australia'
    ),
    (
        '2a922124-7727-4043-b143-79983861311c',
        'Daniel Lee',
        1.0,
        'Germany'
    ),
    (
        '2b3c4d5e-0f1a-2b3c-4d5e-6f7a8b9e0f1a',
        'Olivia Taylor',
        0.0,
        'Japan'
    ),
    (
        '2b4d6f8e-0a1b-3c2d-4e5f-6a7b8d9e0f1a',
        'Ethan Wilson',
        1.0,
        'Brazil'
    ),
    (
        '3839018e-379b-484d-b291-846140324918',
        'Ava Martinez',
        0.0,
        'France'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        'Liam Garcia',
        1.0,
        'Italy'
    ),
    (
        '83846689-569a-42de-957a-5429861290ee',
        'Sophia Adams',
        0.0,
        'Spain'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        'Noah Hernandez',
        1.0,
        'Mexico'
    ),
    (
        'dc45a08a-3c4c-4f56-a93d-5b2605d8743f',
        'Isabella Scott',
        0.0,
        'Sweden'
    ),
    (
        '3c4d5e6f-1a2b-3c4d-5e6f-7a8b9e0f1a2b',
        'Benjamin White',
        1.0,
        'South Korea'
    ),
    (
        '3c5e7f9a-1b2c-3d4e-5f6a-7b8d9e0f1a2c',
        'Mia Turner',
        0.0,
        'India'
    ),
    (
        '3f4a5b6c-7d8e-9f0a-1b2c-3d4e5f6a7b8c',
        'Alexander Hall',
        1.0,
        'Russia'
    ),
    (
        '46e23463-e637-4635-8963-6069a3088431',
        'Charlotte Green',
        0.0,
        'Netherlands'
    ),
    (
        '4c5d6e7f-8a9b-0c1d-2e3f-4a5b6c7d8e9f',
        'William Adams',
        1.0,
        'Argentina'
    ),
    (
        '4d5e6f7a-2b3c-4d5e-6f7a-8b9e0f1a2b3c',
        'Amelia Rodriguez',
        0.0,
        'Switzerland'
    ),
    (
        '87b281b6-40a2-441d-8354-b030525bcfd9',
        'Budi Setiawan',
        1.0,
        'Indonesia'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        'Blick Ryan',
        0.0,
        'USA'
    ),
    (
        '4d6f8e0a-2b3c-4d5e-6f7a-8b9e0f1a2b3c',
        'Chandra Wijaya',
        1.0,
        'Canada'
    ),
    (
        '5306068f-8988-4e15-a282-513631916164',
        'Keanu Sean',
        0.0,
        'UK'
    ),
    (
        '57209911-2300-461b-a42f-60a174306a1c',
        'Endro Susilo',
        1.0,
        'Australia'
    ),
    (
        '5b6c7d8e-9f0a-1b2c-3d4e-5f6a7b8c9d0e',
        'Agus Setiawan',
        0.0,
        'Indonesia'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        'Robb Usher',
        1.0,
        'USA'
    ),
    (
        '962ee531-bd9a-454e-94e8-b29fc0598c1a',
        'Bob Marley',
        0.0,
        'Canada'
    ),
    (
        '5e6f7a8b-3c4d-5e6f-7a8b-9e0f1a2b3c4d',
        'Sarah Condor',
        1.0,
        'UK'
    ),
    (
        '2599833e-3011-4c08-bb64-7875c32235a5',
        'Will Chan',
        0.0,
        'Australia'
    ),
    (
        '644933e8-8283-4454-952d-156545310190',
        'Kartika Adinata',
        1.0,
        'Indonesia'
    ),
    (
        '6a7b8c9d-0e1f-2a3b-4c5d-6e7f8a9b0c1d',
        'Ken Black',
        0.0,
        'USA'
    ),
    (
        '6f7a8b9e-4c5d-6e7f-8a9b-0f1a2b3c4d5e',
        'Elizabeth Kusuma',
        1.0,
        'Canada'
    ),
    (
        'd65e9164-7f86-40b3-aac6-de326f937630',
        'Adrian Stuart',
        0.0,
        'UK'
    ),
    (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        'Oki Cahya',
        1.0,
        'Australia'
    ),
    (
        '6f8e0a1b-4c5d-6e7f-8a9b-0f1a2b3c4d5e',
        'Stef Mansyur',
        0.0,
        'Indonesia'
    ),
    (
        '76911232-6e06-457e-861c-225618306179',
        'Riani Belle',
        1.0,
        'USA'
    ),
    (
        '7a170185-080f-4e8a-9063-80b656416237',
        'Jamie Lann',
        0.0,
        'Canada'
    ),
    (
        '7a8b9e0f-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        'Anastasya Petrova',
        1.0,
        'Rusia'
    ),
    (
        '3fb8c337-69bd-417d-903f-096fe5d262d7',
        'Beatrice Bianchi',
        1.0,
        'Italia'
    ),
    (
        '7d8e9f0a-1b2c-3d4e-5f6a-7b8c9d0e1f2a',
        'Chen Li',
        0.0,
        'Tiongkok'
    ),
    (
        '81716651-7359-491a-961c-266206e7987d',
        'David Johnson',
        0.0,
        'Amerika Serikat'
    ),
    (
        '8b9e0f1a-6a7b-8d9e-0f1a-2b3c4d5e6f7a',
        'Elif Aydemir',
        1.0,
        'Turki'
    ),
    (
        '3b2fa36c-4e15-4d07-84c9-5ae1b3298ff7',
        'Fatma Mohammed',
        1.0,
        'Mesir'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        'Gabriela Fernandez',
        1.0,
        'Spanyol'
    ),
    (
        '20583eea-a547-4e15-ad35-165c43efeee2',
        'Hiroki Tanaka',
        0.0,
        'Jepang'
    ),
    (
        '9381869b-d664-489a-867e-53918447739c',
        'Indra Wijaya',
        0.0,
        'Indonesia'
    ),
    (
        '943d1221-464a-4943-8327-8136975b9384',
        'Jasmine Lee',
        1.0,
        'Korea Selatan'
    ),
    (
        '9b0c1d2e-3f4a-5b6c-7d8e-9f0a1b2c3d4e',
        'Kevin Müller',
        0.0,
        'Jerman'
    ),
    (
        '9e0f1a2b-7c8d-9e0f-1a2b-3c4d5e6f7a8b',
        'Laura Garcia',
        1.0,
        'Meksiko'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        'Mohammed Ahmed',
        0.0,
        'Arab Saudi'
    ),
    (
        'c22c5b2c-c9cf-4e97-91f1-6bd34c5782f0',
        'Nadia Hussain',
        1.0,
        'Pakistan'
    ),
    (
        'a4574498-2499-4201-9383-199604073527',
        'Olivia Smith',
        1.0,
        'Inggris'
    ),
    (
        'b237357f-3673-4493-93a4-d52863232252',
        'Pedro Oliveira',
        0.0,
        'Portugal'
    ),
    (
        'c6009541-2f98-4965-9444-2757516b257e',
        'Qais Ahmed',
        0.0,
        'Bangladesh'
    ),
    (
        'd56e1576-6312-453d-9e47-2694f614a125',
        'Rania Hussein',
        1.0,
        'Yordania'
    ),
    (
        'e196603a-953d-478a-ad18-05083893f53c',
        'Sofia Dimitriadis',
        1.0,
        'Yunani'
    ),
    (
        'f1e4865c-304a-493b-b781-9c5f66486638',
        'Thomas Dubois',
        0.0,
        'Prancis'
    ),
    (
        '095015f7-2533-418e-99e6-60421976190b',
        'John Doe',
        0.0,
        'Uganda'
    );

INSERT INTO
    PENULIS_SKENARIO
VALUES (
        '343a2916-a547-4917-af69-f9305a118854'
    ),
    (
        '0c1d2e3f-4a5b-6c7d-8e9f-0a1b2c3d4e5f'
    ),
    (
        '0e1f2a3b-4c5d-6e7f-8a9b-0c1d2e3f4a5b'
    ),
    (
        '0f1a2b3c-8d9e-0f1a-2b3c-4d5e6f7a8b9e'
    ),
    (
        '11299894-832d-417a-a347-82176e700746'
    ),
    (
        '1a2b3c4d-9e0f-1a2b-3c4d-5e6f7a8b9e0f'
    ),
    (
        '1a3c6f7d-8b9e-4f0a-9b1c-2d3e4f5a6b7c'
    ),
    (
        '1b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f'
    ),
    (
        'a43d6971-04d3-46d5-8229-4bbbde4f0f78'
    ),
    (
        '25e223f4-428a-4616-927c-6061d1923614'
    ),
    (
        '2a3b4c5d-6e7f-8a9b-0c1d-2e3f4a5b6c7d'
    ),
    (
        'f38fe383-8e1c-4203-af26-4c8d92f012b6'
    ),
    (
        '2a922124-7727-4043-b143-79983861311c'
    ),
    (
        '2b3c4d5e-0f1a-2b3c-4d5e-6f7a8b9e0f1a'
    ),
    (
        '2b4d6f8e-0a1b-3c2d-4e5f-6a7b8d9e0f1a'
    ),
    (
        '3839018e-379b-484d-b291-846140324918'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d'
    ),
    (
        '83846689-569a-42de-957a-5429861290ee'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e'
    ),
    (
        'dc45a08a-3c4c-4f56-a93d-5b2605d8743f'
    ),
    (
        '3c4d5e6f-1a2b-3c4d-5e6f-7a8b9e0f1a2b'
    ),
    (
        '3c5e7f9a-1b2c-3d4e-5f6a-7b8d9e0f1a2c'
    ),
    (
        '3f4a5b6c-7d8e-9f0a-1b2c-3d4e5f6a7b8c'
    ),
    (
        '46e23463-e637-4635-8963-6069a3088431'
    ),
    (
        '4c5d6e7f-8a9b-0c1d-2e3f-4a5b6c7d8e9f'
    ),
    (
        '4d5e6f7a-2b3c-4d5e-6f7a-8b9e0f1a2b3c'
    ),
    (
        '87b281b6-40a2-441d-8354-b030525bcfd9'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a'
    ),
    (
        '4d6f8e0a-2b3c-4d5e-6f7a-8b9e0f1a2b3c'
    );

INSERT INTO
    PEMAIN
VALUES (
        '095015f7-2533-418e-99e6-60421976190b'
    ),
    (
        '0c1d2e3f-4a5b-6c7d-8e9f-0a1b2c3d4e5f'
    ),
    (
        '0e1f2a3b-4c5d-6e7f-8a9b-0c1d2e3f4a5b'
    ),
    (
        '0f1a2b3c-8d9e-0f1a-2b3c-4d5e6f7a8b9e'
    ),
    (
        '11299894-832d-417a-a347-82176e700746'
    ),
    (
        '1a2b3c4d-9e0f-1a2b-3c4d-5e6f7a8b9e0f'
    ),
    (
        '1a3c6f7d-8b9e-4f0a-9b1c-2d3e4f5a6b7c'
    ),
    (
        '1b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f'
    ),
    (
        'a43d6971-04d3-46d5-8229-4bbbde4f0f78'
    ),
    (
        '25e223f4-428a-4616-927c-6061d1923614'
    ),
    (
        '2a3b4c5d-6e7f-8a9b-0c1d-2e3f4a5b6c7d'
    ),
    (
        'f38fe383-8e1c-4203-af26-4c8d92f012b6'
    ),
    (
        '2a922124-7727-4043-b143-79983861311c'
    ),
    (
        '2b3c4d5e-0f1a-2b3c-4d5e-6f7a8b9e0f1a'
    ),
    (
        '2b4d6f8e-0a1b-3c2d-4e5f-6a7b8d9e0f1a'
    ),
    (
        '3839018e-379b-484d-b291-846140324918'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d'
    ),
    (
        '83846689-569a-42de-957a-5429861290ee'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e'
    ),
    (
        'dc45a08a-3c4c-4f56-a93d-5b2605d8743f'
    ),
    (
        '3c4d5e6f-1a2b-3c4d-5e6f-7a8b9e0f1a2b'
    ),
    (
        '3c5e7f9a-1b2c-3d4e-5f6a-7b8d9e0f1a2c'
    ),
    (
        '3f4a5b6c-7d8e-9f0a-1b2c-3d4e5f6a7b8c'
    ),
    (
        '46e23463-e637-4635-8963-6069a3088431'
    ),
    (
        '4c5d6e7f-8a9b-0c1d-2e3f-4a5b6c7d8e9f'
    ),
    (
        '4d5e6f7a-2b3c-4d5e-6f7a-8b9e0f1a2b3c'
    ),
    (
        '87b281b6-40a2-441d-8354-b030525bcfd9'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a'
    ),
    (
        '4d6f8e0a-2b3c-4d5e-6f7a-8b9e0f1a2b3c'
    ),
    (
        '5306068f-8988-4e15-a282-513631916164'
    ),
    (
        '57209911-2300-461b-a42f-60a174306a1c'
    ),
    (
        '5b6c7d8e-9f0a-1b2c-3d4e-5f6a7b8c9d0e'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b'
    ),
    (
        '962ee531-bd9a-454e-94e8-b29fc0598c1a'
    ),
    (
        '5e6f7a8b-3c4d-5e6f-7a8b-9e0f1a2b3c4d'
    ),
    (
        '2599833e-3011-4c08-bb64-7875c32235a5'
    ),
    (
        '644933e8-8283-4454-952d-156545310190'
    ),
    (
        '6a7b8c9d-0e1f-2a3b-4c5d-6e7f8a9b0c1d'
    ),
    (
        '6f7a8b9e-4c5d-6e7f-8a9b-0f1a2b3c4d5e'
    );

INSERT INTO
    SUTRADARA
VALUES (
        '9b0c1d2e-3f4a-5b6c-7d8e-9f0a1b2c3d4e'
    ),
    (
        '9e0f1a2b-7c8d-9e0f-1a2b-3c4d5e6f7a8b'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f'
    ),
    (
        'c22c5b2c-c9cf-4e97-91f1-6bd34c5782f0'
    ),
    (
        'a4574498-2499-4201-9383-199604073527'
    ),
    (
        'b237357f-3673-4493-93a4-d52863232252'
    ),
    (
        'c6009541-2f98-4965-9444-2757516b257e'
    ),
    (
        'd56e1576-6312-453d-9e47-2694f614a125'
    ),
    (
        'e196603a-953d-478a-ad18-05083893f53c'
    ),
    (
        'f1e4865c-304a-493b-b781-9c5f66486638'
    );

INSERT INTO
    TAYANGAN
VALUES (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        'Inception',
        'Dom Cobb mencuri rahasia dari alam bawah sadar orang dalam mimpi. Tugas terbarunya adalah menanamkan ide di pikiran seseorang tanpa diketahui.',
        'Indonesia',
        'Menyelinap ke dalam mimpi orang lain, seorang pencuri berusaha untuk melakukan inisiasi terakhir, mengubah dunia.',
        'https://www.example.com/inception_trailer',
        '2023-06-15 00:00:00',
        '9b0c1d2e-3f4a-5b6c-7d8e-9f0a1b2c3d4e'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        'Parasite',
        'Keluarga Kim merampok kehidupan keluarga Park yang kaya sebagai pegawai rumah tangga, namun rahasia gelap terungkap.',
        'USA',
        'Keluarga miskin mengambil alih kehidupan keluarga kaya, tetapi rahasia mereka membawa kehancuran.',
        'https://www.example.com/parasite_trailer',
        '2022-11-20 00:00:00',
        '9e0f1a2b-7c8d-9e0f-1a2b-3c4d5e6f7a8b'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        'Titanic',
        'Kisah cinta epik Jack dan Rose yang terancam oleh bencana kapal Titanic.',
        'Canada',
        'Di atas kapal legendaris, cinta berkembang, tetapi bencana menantinya di lautan.',
        'https://www.example.com/titanic_trailer',
        '2024-03-10 00:00:00',
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        'Breaking Bad',
        'Walter White membuat metamfetamin setelah didiagnosis kanker, memasuki dunia kejahatan bersama Jesse Pinkman.',
        'UK',
        'Seorang guru kimia yang putus asa menjadi raja narkoba di bawah tanah.',
        'https://www.example.com/breakingbad_trailer',
        '2023-08-05 00:00:00',
        'c22c5b2c-c9cf-4e97-91f1-6bd34c5782f0'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        'Game of Thrones',
        'Pertempuran antar keluarga bangsawan untuk merebut Iron Throne di Westeros.',
        'Australia',
        'Pertempuran sengit antara keluarga bangsawan untuk mendapatkan takhta besi yang didambakan.',
        'https://www.example.com/gameofthrones_trailer',
        '2022-09-25 00:00:00',
        'a4574498-2499-4201-9383-199604073527'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        'Friends',
        'Enam teman di New York mendukung satu sama lain melalui cinta dan kegembiraan.',
        'Germany',
        'Persahabatan, cinta, dan kekonyolan dalam kehidupan sehari-hari di kota New York.',
        'https://www.example.com/friends_trailer',
        '2023-04-30 00:00:00',
        'b237357f-3673-4493-93a4-d52863232252'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        'The Crown',
        'Kisah kehidupan Ratu Elizabeth II dari masa mudanya hingga puncak kekuasaannya.',
        'Japan',
        'Di balik kemegahan kerajaan, ada konflik, pengkhianatan, dan cinta yang rumit.',
        'https://www.example.com/thecrown_trailer',
        '2024-01-15 00:00:00',
        'c6009541-2f98-4965-9444-2757516b257e'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        'Stranger Things',
        'Anak-anak di Hawkins, Indiana, menghadapi kejadian aneh, termasuk monster dari Upside Down.',
        'Brazil',
        'Anak-anak menemukan rahasia yang gelap di kota kecil mereka, dan monster dari dimensi lain mengintai.',
        'https://www.example.com/strangerthings_trailer',
        '2022-12-20 00:00:00',
        'd56e1576-6312-453d-9e47-2694f614a125'
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        'The Matrix',
        'Neo memimpin pemberontakan melawan mesin yang menguasai dunia maya.',
        'Zimbabwe',
        'Neo menemukan kebenaran mengerikan tentang realitas dan memimpin pemberontakan melawan mesin.',
        'https://www.example.com/matrix_trailer',
        '2023-10-10 00:00:00',
        'e196603a-953d-478a-ad18-05083893f53c'
    ),
    (
        'd217422a-30d3-4872-b1be-d842724f2cb8',
        'Slumdog Millionaire',
        'Jamal Malik menceritakan kisah hidupnya melalui pertanyaan dalam Who Wants to Be a Millionaire.',
        'Singapore',
        'Seorang pria miskin memiliki kesempatan besar untuk mengubah hidupnya di atas panggung terbesar di dunia.',
        'https://www.example.com/slumdogmillionaire_trailer',
        '2024-02-05 00:00:00',
        'f1e4865c-304a-493b-b781-9c5f66486638'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        'The Office',
        'Kehidupan karyawan kantor Dunder Mifflin di Scranton, Pennsylvania, dipimpin oleh manajer eksentrik, Michael Scott.',
        'USA',
        'Komedi lucu tentang kehidupan di kantor, dengan manajer yang aneh dan karyawan yang unik.',
        'https://www.example.com/theoffice_trailer',
        '2023-07-10 00:00:00',
        '9b0c1d2e-3f4a-5b6c-7d8e-9f0a1b2c3d4e'
    ),
    (
        'd35ae7cf-f812-4524-876b-7cae4d46f127',
        'Sherlock',
        'Sherlock Holmes dan Dr. Watson menyelesaikan kasus kriminal di London.',
        'Argentina',
        'Petualangan detektif yang menegangkan dengan misteri yang rumit dan teka-teki yang membingungkan.',
        'https://www.example.com/sherlock_trailer',
        '2022-08-15 00:00:00',
        '9e0f1a2b-7c8d-9e0f-1a2b-3c4d5e6f7a8b'
    ),
    (
        'f8d81d60-b5c0-4ae8-a1d0-132beb7585ba',
        'The Mandalorian',
        'Seorang pemburu bayaran menjelajahi galaksi sambil menjaga seorang anak yang dicari.',
        'Italy',
        'Di alam semesta Star Wars, seorang pemburu bayaran melintasi galaksi dengan misi yang berbahaya.',
        'https://www.example.com/mandalorian_trailer',
        '2024-05-20 00:00:00',
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f'
    ),
    (
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        'The Godfather',
        'Saga keluarga kriminal yang dipimpin oleh Don Vito Corleone, mengungkapkan konflik antara keluarga dan keinginan pribadi.',
        'Japan',
        'Kekuasaan, pengkhianatan, dan dendam menguasai keluarga kriminal Corleone.',
        'https://www.example.com/godfather_trailer',
        '2023-09-25 00:00:00',
        'c22c5b2c-c9cf-4e97-91f1-6bd34c5782f0'
    ),
    (
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        'Black Panther',
        'T''Challa, di Wakanda, melawan musuh untuk mempertahankan takhta dan mengungkapkan rahasia keluarganya.',
        'South Korea',
        'Wakanda terancam oleh musuh dalam, dan T''Challa harus menjadi pahlawan yang dibutuhkan.',
        'https://www.example.com/blackpanther_trailer',
        '2022-10-30 00:00:00',
        'a4574498-2499-4201-9383-199604073527'
    ),
    (
        '9271fd7b-5d44-4570-b207-daa5a90e03ae',
        'Interstellar',
        'Penjelajah antariksa mencari planet pengganti Bumi untuk menyelamatkan umat manusia dari kelaparan.',
        'South Africa',
        'Penjelajah antariksa melintasi lubang cacing dalam pencarian planet baru untuk manusia.',
        'https://www.example.com/interstellar_trailer',
        '2024-03-05 00:00:00',
        'b237357f-3673-4493-93a4-d52863232252'
    ),
    (
        '1e32a378-6c89-4607-b981-abd702f129f0',
        'The Witcher',
        'Geralt of Rivia menjelajahi dunia fantasi yang gelap dan berbahaya.',
        'UK',
        'Seorang pemburu monster melintasi dunia yang penuh kejahatan dan keajaiban.',
        'https://www.example.com/witcher_trailer',
        '2023-11-10 00:00:00',
        'c6009541-2f98-4965-9444-2757516b257e'
    ),
    (
        'e3b53e4e-d008-4d13-b74c-a0a1ae60e5df',
        'La La Land',
        'Kisah cinta musikal antara Sebastian dan Mia di Los Angeles yang berkilauan.',
        'USA',
        'Cinta, mimpi, dan ketegangan di dunia Hollywood yang berkilauan.',
        'https://www.example.com/lalaland_trailer',
        '2022-12-15 00:00:00',
        'd56e1576-6312-453d-9e47-2694f614a125'
    ),
    (
        '9cdcdd5f-1826-499e-ab11-a040d2c1ea2e',
        'WestWorld',
        'Taman hiburan futuristik dengan android yang menyadari identitas mereka, menyebabkan kekacauan.',
        'Tajikistan',
        'Di taman hiburan futuristik, tamu-tamu dihadapkan pada pilihan moral yang sulit dan bahaya yang tak terduga.',
        'https://www.example.com/westworld_trailer',
        '2024-01-20 00:00:00',
        'e196603a-953d-478a-ad18-05083893f53c'
    ),
    (
        'e1471b78-013f-4828-8a3e-381e67888232',
        'Jurassic Park',
        'Dinosaurus berkeliaran bebas setelah sistem keamanan gagal di taman hiburan.',
        'Croatia',
        'Dinosaurus hidup lagi, dan sekarang mereka bebas di taman bermain yang telah dibuat manusia.',
        'https://www.example.com/jurassicpark_trailer',
        '2023-02-25 00:00:00',
        'f1e4865c-304a-493b-b781-9c5f66486638'
    );

INSERT INTO
    PENGGUNA
VALUES (
        'alice_johnson',
        'secret123',
        'Indonesia'
    ),
    (
        'david_smith',
        'mypass456',
        'USA'
    ),
    (
        'emma_wilson',
        'secure789',
        'Canada'
    ),
    (
        'henry_clark',
        'access987',
        'UK'
    ),
    (
        'isabella_lee',
        'pass1234',
        'Australia'
    ),
    (
        'jackson_kim',
        'secret567',
        'Germany'
    ),
    (
        'lily_tan',
        'mypass890',
        'Japan'
    ),
    (
        'mason_choi',
        'secure012',
        'Brazil'
    );

INSERT INTO
    DUKUNGAN_PERANGKAT
VALUES ('Basic', 'Smartphone'),
    ('Basic', 'Tablet'),
    ('Standard', 'Smartphone'),
    ('Standard', 'Tablet'),
    ('Premium', 'Smartphone'),
    ('Premium', 'Tablet'),
    ('Premium', 'Smart TV'),
    ('Premium', 'Laptop');

INSERT INTO
    TRANSACTION
VALUES (
        'alice_johnson',
        '2023-03-15 00:00:00',
        '2023-04-10 00:00:00',
        'Basic',
        'Credit Card',
        '2023-03-14 18:30:00'
    ),
    (
        'david_smith',
        '2023-06-20 00:00:00',
        '2023-07-15 00:00:00',
        'Standard',
        'PayPal',
        '2023-06-19 14:45:00'
    ),
    (
        'emma_wilson',
        '2023-02-10 00:00:00',
        '2023-03-10 00:00:00',
        'Basic',
        'Bank Transfer',
        '2023-02-09 21:15:00'
    ),
    (
        'henry_clark',
        '2023-05-05 00:00:00',
        '2023-06-05 00:00:00',
        'Premium',
        'Credit Card',
        '2023-05-04 09:00:00'
    ),
    (
        'isabella_lee',
        '2023-01-25 00:00:00',
        '2023-02-25 00:00:00',
        'Standard',
        'PayPal',
        '2023-01-24 16:20:00'
    ),
    (
        'jackson_kim',
        '2023-04-18 00:00:00',
        '2023-05-18 00:00:00',
        'Premium',
        'Bank Transfer',
        '2023-04-17 11:30:00'
    ),
    (
        'lily_tan',
        '2023-03-05 00:00:00',
        '2023-04-05 00:00:00',
        'Basic',
        'Credit Card',
        '2023-03-04 19:50:00'
    ),
    (
        'mason_choi',
        '2023-06-10 00:00:00',
        '2023-07-10 00:00:00',
        'Premium',
        'PayPal',
        '2023-06-09 08:40:00'
    ),
    (
        'alice_johnson',
        '2023-02-15 00:00:00',
        '2023-03-15 00:00:00',
        'Standard',
        'Bank Transfer',
        '2023-02-14 22:05:00'
    ),
    (
        'david_smith',
        '2023-05-20 00:00:00',
        '2023-06-20 00:00:00',
        'Premium',
        'Credit Card',
        '2023-05-19 12:10:00'
    ),
    (
        'emma_wilson',
        '2023-01-10 00:00:00',
        '2023-02-10 00:00:00',
        'Basic',
        'PayPal',
        '2023-01-09 17:00:00'
    ),
    (
        'henry_clark',
        '2023-04-05 00:00:00',
        '2023-05-05 00:00:00',
        'Standard',
        'Bank Transfer',
        '2023-04-04 10:25:00'
    ),
    (
        'isabella_lee',
        '2023-03-20 00:00:00',
        '2023-04-20 00:00:00',
        'Basic',
        'Credit Card',
        '2023-03-19 23:55:00'
    ),
    (
        'jackson_kim',
        '2023-06-25 00:00:00',
        '2023-07-25 00:00:00',
        'Premium',
        'PayPal',
        '2023-06-24 07:15:00'
    ),
    (
        'lily_tan',
        '2023-02-05 00:00:00',
        '2023-03-05 00:00:00',
        'Standard',
        'Bank Transfer',
        '2023-02-04 20:40:00'
    ),
    (
        'mason_choi',
        '2023-05-10 00:00:00',
        '2023-06-10 00:00:00',
        'Premium',
        'Credit Card',
        '2023-05-09 13:30:00'
    ),
    (
        'alice_johnson',
        '2023-08-15 00:00:00',
        '2023-09-10 00:00:00',
        'Basic',
        'Credit Card',
        '2023-08-14 17:45:00'
    ),
    (
        'david_smith',
        '2023-11-20 00:00:00',
        '2023-12-15 00:00:00',
        'Standard',
        'PayPal',
        '2023-11-19 15:00:00'
    ),
    (
        'emma_wilson',
        '2023-07-10 00:00:00',
        '2023-08-10 00:00:00',
        'Basic',
        'Bank Transfer',
        '2023-07-09 22:30:00'
    ),
    (
        'henry_clark',
        '2023-10-05 00:00:00',
        '2023-11-05 00:00:00',
        'Premium',
        'Credit Card',
        '2023-10-04 10:10:00'
    ),
    (
        'isabella_lee',
        '2023-05-20 00:00:00',
        '2023-06-20 00:00:00',
        'Premium',
        'Credit Card',
        '2023-05-19 12:10:00'
    ),
    (
        'jackson_kim',
        '2023-01-10 00:00:00',
        '2023-02-10 00:00:00',
        'Basic',
        'PayPal',
        '2023-01-09 17:00:00'
    ),
    (
        'lily_tan',
        '2023-07-10 00:00:00',
        '2023-08-10 00:00:00',
        'Basic',
        'Bank Transfer',
        '2023-07-09 22:30:00'
    ),
    (
        'mason_choi',
        '2023-10-05 00:00:00',
        '2023-11-05 00:00:00',
        'Premium',
        'Credit Card',
        '2023-10-04 10:10:00'
    );

INSERT INTO
    MEMAINKAN_TAYANGAN
VALUES (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        '095015f7-2533-418e-99e6-60421976190b'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        '0c1d2e3f-4a5b-6c7d-8e9f-0a1b2c3d4e5f'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        '0e1f2a3b-4c5d-6e7f-8a9b-0c1d2e3f4a5b'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        '0f1a2b3c-8d9e-0f1a-2b3c-4d5e6f7a8b9e'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        '11299894-832d-417a-a347-82176e700746'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        '1a2b3c4d-9e0f-1a2b-3c4d-5e6f7a8b9e0f'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        '1a3c6f7d-8b9e-4f0a-9b1c-2d3e4f5a6b7c'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        '1b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e'
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f'
    ),
    (
        'd217422a-30d3-4872-b1be-d842724f2cb8',
        'a43d6971-04d3-46d5-8229-4bbbde4f0f78'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        '25e223f4-428a-4616-927c-6061d1923614'
    ),
    (
        'd35ae7cf-f812-4524-876b-7cae4d46f127',
        '2a3b4c5d-6e7f-8a9b-0c1d-2e3f4a5b6c7d'
    ),
    (
        'f8d81d60-b5c0-4ae8-a1d0-132beb7585ba',
        'f38fe383-8e1c-4203-af26-4c8d92f012b6'
    ),
    (
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        '2a922124-7727-4043-b143-79983861311c'
    ),
    (
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        '2b3c4d5e-0f1a-2b3c-4d5e-6f7a8b9e0f1a'
    ),
    (
        '9271fd7b-5d44-4570-b207-daa5a90e03ae',
        '2b4d6f8e-0a1b-3c2d-4e5f-6a7b8d9e0f1a'
    ),
    (
        '1e32a378-6c89-4607-b981-abd702f129f0',
        '3839018e-379b-484d-b291-846140324918'
    ),
    (
        'e3b53e4e-d008-4d13-b74c-a0a1ae60e5df',
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d'
    ),
    (
        '9cdcdd5f-1826-499e-ab11-a040d2c1ea2e',
        '83846689-569a-42de-957a-5429861290ee'
    ),
    (
        'e1471b78-013f-4828-8a3e-381e67888232',
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e'
    ),
    (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        'dc45a08a-3c4c-4f56-a93d-5b2605d8743f'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        '3c4d5e6f-1a2b-3c4d-5e6f-7a8b9e0f1a2b'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        '3c5e7f9a-1b2c-3d4e-5f6a-7b8d9e0f1a2c'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        '3f4a5b6c-7d8e-9f0a-1b2c-3d4e5f6a7b8c'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        '46e23463-e637-4635-8963-6069a3088431'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        '4c5d6e7f-8a9b-0c1d-2e3f-4a5b6c7d8e9f'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        '4d5e6f7a-2b3c-4d5e-6f7a-8b9e0f1a2b3c'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        '87b281b6-40a2-441d-8354-b030525bcfd9'
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a'
    ),
    (
        'd217422a-30d3-4872-b1be-d842724f2cb8',
        '4d6f8e0a-2b3c-4d5e-6f7a-8b9e0f1a2b3c'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        '5306068f-8988-4e15-a282-513631916164'
    ),
    (
        'd35ae7cf-f812-4524-876b-7cae4d46f127',
        '57209911-2300-461b-a42f-60a174306a1c'
    ),
    (
        'f8d81d60-b5c0-4ae8-a1d0-132beb7585ba',
        '5b6c7d8e-9f0a-1b2c-3d4e-5f6a7b8c9d0e'
    ),
    (
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b'
    ),
    (
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        '962ee531-bd9a-454e-94e8-b29fc0598c1a'
    ),
    (
        '9271fd7b-5d44-4570-b207-daa5a90e03ae',
        '5e6f7a8b-3c4d-5e6f-7a8b-9e0f1a2b3c4d'
    ),
    (
        '1e32a378-6c89-4607-b981-abd702f129f0',
        '2599833e-3011-4c08-bb64-7875c32235a5'
    ),
    (
        'e3b53e4e-d008-4d13-b74c-a0a1ae60e5df',
        '644933e8-8283-4454-952d-156545310190'
    ),
    (
        '9cdcdd5f-1826-499e-ab11-a040d2c1ea2e',
        '6a7b8c9d-0e1f-2a3b-4c5d-6e7f8a9b0c1d'
    ),
    (
        'e1471b78-013f-4828-8a3e-381e67888232',
        '6f7a8b9e-4c5d-6e7f-8a9b-0f1a2b3c4d5e'
    ),
    (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        '4d5e6f7a-2b3c-4d5e-6f7a-8b9e0f1a2b3c'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        '87b281b6-40a2-441d-8354-b030525bcfd9'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        '4d6f8e0a-2b3c-4d5e-6f7a-8b9e0f1a2b3c'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        '5306068f-8988-4e15-a282-513631916164'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        '57209911-2300-461b-a42f-60a174306a1c'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        '5b6c7d8e-9f0a-1b2c-3d4e-5f6a7b8c9d0e'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b'
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        '962ee531-bd9a-454e-94e8-b29fc0598c1a'
    ),
    (
        'd217422a-30d3-4872-b1be-d842724f2cb8',
        '5e6f7a8b-3c4d-5e6f-7a8b-9e0f1a2b3c4d'
    );

INSERT INTO
    MENULIS_SKENARIO_TAYANGAN
VALUES (
        '1e32a378-6c89-4607-b981-abd702f129f0',
        '343a2916-a547-4917-af69-f9305a118854'
    ),
    (
        'e3b53e4e-d008-4d13-b74c-a0a1ae60e5df',
        '0c1d2e3f-4a5b-6c7d-8e9f-0a1b2c3d4e5f'
    ),
    (
        '9cdcdd5f-1826-499e-ab11-a040d2c1ea2e',
        '0e1f2a3b-4c5d-6e7f-8a9b-0c1d2e3f4a5b'
    ),
    (
        'e1471b78-013f-4828-8a3e-381e67888232',
        '0f1a2b3c-8d9e-0f1a-2b3c-4d5e6f7a8b9e'
    ),
    (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        '11299894-832d-417a-a347-82176e700746'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        '1a2b3c4d-9e0f-1a2b-3c4d-5e6f7a8b9e0f'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        '1a3c6f7d-8b9e-4f0a-9b1c-2d3e4f5a6b7c'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        '1b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        'a43d6971-04d3-46d5-8229-4bbbde4f0f78'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        '25e223f4-428a-4616-927c-6061d1923614'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        '2a3b4c5d-6e7f-8a9b-0c1d-2e3f4a5b6c7d'
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        'f38fe383-8e1c-4203-af26-4c8d92f012b6'
    ),
    (
        'd217422a-30d3-4872-b1be-d842724f2cb8',
        '2a922124-7727-4043-b143-79983861311c'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        '2b3c4d5e-0f1a-2b3c-4d5e-6f7a8b9e0f1a'
    ),
    (
        'd35ae7cf-f812-4524-876b-7cae4d46f127',
        '2b4d6f8e-0a1b-3c2d-4e5f-6a7b8d9e0f1a'
    ),
    (
        'f8d81d60-b5c0-4ae8-a1d0-132beb7585ba',
        '3839018e-379b-484d-b291-846140324918'
    ),
    (
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d'
    ),
    (
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        '83846689-569a-42de-957a-5429861290ee'
    ),
    (
        '9271fd7b-5d44-4570-b207-daa5a90e03ae',
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e'
    ),
    (
        '1e32a378-6c89-4607-b981-abd702f129f0',
        'dc45a08a-3c4c-4f56-a93d-5b2605d8743f'
    ),
    (
        'e3b53e4e-d008-4d13-b74c-a0a1ae60e5df',
        '3c4d5e6f-1a2b-3c4d-5e6f-7a8b9e0f1a2b'
    ),
    (
        '9cdcdd5f-1826-499e-ab11-a040d2c1ea2e',
        '3c5e7f9a-1b2c-3d4e-5f6a-7b8d9e0f1a2c'
    ),
    (
        'e1471b78-013f-4828-8a3e-381e67888232',
        '3f4a5b6c-7d8e-9f0a-1b2c-3d4e5f6a7b8c'
    ),
    (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        '46e23463-e637-4635-8963-6069a3088431'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        '4c5d6e7f-8a9b-0c1d-2e3f-4a5b6c7d8e9f'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        '4d5e6f7a-2b3c-4d5e-6f7a-8b9e0f1a2b3c'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        '87b281b6-40a2-441d-8354-b030525bcfd9'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        '4d6f8e0a-2b3c-4d5e-6f7a-8b9e0f1a2b3c'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        '11299894-832d-417a-a347-82176e700746'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        '1a2b3c4d-9e0f-1a2b-3c4d-5e6f7a8b9e0f'
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        '1a3c6f7d-8b9e-4f0a-9b1c-2d3e4f5a6b7c'
    ),
    (
        'd217422a-30d3-4872-b1be-d842724f2cb8',
        '1b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e'
    );

INSERT INTO
    GENRE_TAYANGAN
VALUES (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        'Science Fiction'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        'Dark Comedy'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        'Thriller'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        'Romance'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        'Drama'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        'Crime'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        'Drama'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        'Fantasy'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        'Comedy'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        'Drama'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        'Horror'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        'Science Fiction'
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        'Action'
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        'Science Fiction'
    ),
    (
        'd217422a-30d3-4872-b1be-d842724f2cb8',
        'Drama'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        'Comedy'
    ),
    (
        'd35ae7cf-f812-4524-876b-7cae4d46f127',
        'Crime'
    ),
    (
        'd35ae7cf-f812-4524-876b-7cae4d46f127',
        'Mystery'
    ),
    (
        'f8d81d60-b5c0-4ae8-a1d0-132beb7585ba',
        'Science Fiction'
    ),
    (
        'f8d81d60-b5c0-4ae8-a1d0-132beb7585ba',
        'Action'
    ),
    (
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        'Drama'
    ),
    (
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        'Crime'
    ),
    (
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        'Action'
    ),
    (
        '9271fd7b-5d44-4570-b207-daa5a90e03ae',
        'Science Fiction'
    ),
    (
        '9271fd7b-5d44-4570-b207-daa5a90e03ae',
        'Drama'
    ),
    (
        '1e32a378-6c89-4607-b981-abd702f129f0',
        'Fantasy'
    ),
    (
        'e3b53e4e-d008-4d13-b74c-a0a1ae60e5df',
        'Romance'
    ),
    (
        '9cdcdd5f-1826-499e-ab11-a040d2c1ea2e',
        'Science Fiction'
    ),
    (
        'e1471b78-013f-4828-8a3e-381e67888232',
        'Science Fiction'
    );

INSERT INTO
    PERUSAHAAN_PRODUKSI
VALUES ('Warner Bros. Pictures'),
    ('Universal Pictures'),
    ('Paramount Pictures'),
    ('Summit Entertainment'),
    ('Celador Films'),
    ('Hartswood Films'),
    ('Deedle-Dee Productions'),
    ('Legendary Pictures'),
    ('Marvel Studios'),
    ('DreamWorks Pictures'),
    ('Netflix'),
    ('HBO'),
    ('Sony Pictures Entertainment'),
    ('A24'),
    ('Lucasfilm Ltd.');

INSERT INTO
    PERSETUJUAN
VALUES (
        'Warner Bros. Pictures',
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        '2023-12-10 00:00:00',
        1826.0,
        30000.0,
        '2024-03-10 00:00:00'
    ),
    (
        'A24',
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        '2023-09-06 00:00:00',
        1826.0,
        25000.0,
        '2023-12-06 00:00:00'
    ),
    (
        'Paramount Pictures',
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        '2023-08-03 00:00:00',
        1826.0,
        28000.0,
        '2023-11-03 00:00:00'
    ),
    (
        'Sony Pictures Entertainment',
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        '2023-12-13 00:00:00',
        1826.0,
        20000.0,
        '2024-03-13 00:00:00'
    ),
    (
        'HBO',
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        '2024-01-10 00:00:00',
        1826.0,
        22000.0,
        '2024-04-10 00:00:00'
    ),
    (
        'Warner Bros. Pictures',
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        '2023-12-02 00:00:00',
        1826.0,
        25000.0,
        '2024-03-02 00:00:00'
    ),
    (
        'Sony Pictures Entertainment',
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        '2023-12-16 00:00:00',
        1826.0,
        25000.0,
        '2024-03-16 00:00:00'
    ),
    (
        'Netflix',
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        '2023-12-17 00:00:00',
        1826.0,
        25000.0,
        '2024-03-17 00:00:00'
    ),
    (
        'Warner Bros. Pictures',
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        '2023-12-18 00:00:00',
        1826.0,
        30000.0,
        '2024-03-18 00:00:00'
    ),
    (
        'Celador Films',
        'd217422a-30d3-4872-b1be-d842724f2cb8',
        '2023-09-07 00:00:00',
        1826.0,
        29000.0,
        '2023-12-07 00:00:00'
    ),
    (
        'Deedle-Dee Productions',
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        '2023-12-20 00:00:00',
        1826.0,
        22000.0,
        '2024-03-20 00:00:00'
    ),
    (
        'Hartswood Films',
        'd35ae7cf-f812-4524-876b-7cae4d46f127',
        '2023-12-21 00:00:00',
        1826.0,
        21000.0,
        '2024-03-21 00:00:00'
    ),
    (
        'Lucasfilm Ltd.',
        'f8d81d60-b5c0-4ae8-a1d0-132beb7585ba',
        '2023-09-01 00:00:00',
        1826.0,
        22000.0,
        '2023-12-01 00:00:00'
    ),
    (
        'Paramount Pictures',
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        '2023-12-23 00:00:00',
        1826.0,
        30000.0,
        '2024-03-23 00:00:00'
    ),
    (
        'Marvel Studios',
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        '2023-12-24 00:00:00',
        1826.0,
        32000.0,
        '2024-03-24 00:00:00'
    ),
    (
        'Legendary Pictures',
        '9271fd7b-5d44-4570-b207-daa5a90e03ae',
        '2023-06-02 00:00:00',
        1826.0,
        31000.0,
        '2023-09-02 00:00:00'
    ),
    (
        'Netflix',
        '1e32a378-6c89-4607-b981-abd702f129f0',
        '2023-12-26 00:00:00',
        1826.0,
        20000.0,
        '2024-03-26 00:00:00'
    ),
    (
        'Summit Entertainment',
        'e3b53e4e-d008-4d13-b74c-a0a1ae60e5df',
        '2023-09-02 00:00:00',
        1826.0,
        350000.0,
        '2023-12-02 00:00:00'
    ),
    (
        'HBO',
        '9cdcdd5f-1826-499e-ab11-a040d2c1ea2e',
        '2023-12-28 00:00:00',
        1826.0,
        200000.0,
        '2024-03-28 00:00:00'
    ),
    (
        'Universal Pictures',
        'e1471b78-013f-4828-8a3e-381e67888232',
        '2023-08-04 00:00:00',
        1826.0,
        34000.0,
        '2023-11-04 00:00:00'
    );

INSERT INTO
    SERIES
VALUES (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d'
    ),
    (
        'd35ae7cf-f812-4524-876b-7cae4d46f127'
    ),
    (
        'f8d81d60-b5c0-4ae8-a1d0-132beb7585ba'
    ),
    (
        '1e32a378-6c89-4607-b981-abd702f129f0'
    ),
    (
        '9cdcdd5f-1826-499e-ab11-a040d2c1ea2e'
    );

INSERT INTO
    FILM
VALUES (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        'https://www.example.com/inception_movie',
        '2010-07-08 00:00:00',
        148.0
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        'https://www.example.com/parasite_movie',
        '2019-05-30 00:00:00',
        132.0
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        'https://www.example.com/titanic_movie',
        '1997-12-19 00:00:00',
        195.0
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        'https://www.example.com/matrix_movie',
        '1999-03-31 00:00:00',
        136.0
    ),
    (
        'd217422a-30d3-4872-b1be-d842724f2cb8',
        'https://www.example.com/slumdogmillionaire_movie',
        '2009-01-09 00:00:00',
        121.0
    ),
    (
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        'https://www.example.com/godfather_movie',
        '1972-03-24 00:00:00',
        175.0
    ),
    (
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        'https://www.example.com/blackpanther_movie',
        '2018-02-16 00:00:00',
        134.0
    ),
    (
        '9271fd7b-5d44-4570-b207-daa5a90e03ae',
        'https://www.example.com/interstellar_movie',
        '2014-11-05 00:00:00',
        169.0
    ),
    (
        'e3b53e4e-d008-4d13-b74c-a0a1ae60e5df',
        'https://www.example.com/lalaland_movie',
        '2016-12-09 00:00:00',
        128.0
    ),
    (
        'e1471b78-013f-4828-8a3e-381e67888232',
        'https://www.example.com/jurassicpark_movie',
        '1993-06-11 00:00:00',
        127.0
    );

INSERT INTO
    EPISODE
VALUES (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        'Pilot',
        'Seorang guru kimia yang putus asa, Walter White, menerima diagnosis kanker yang fatal. Untuk mengamankan masa depan keluarganya, dia memutuskan untuk memasuki dunia produksi',
        58.0,
        'https://www.example.com/breakingbad_1',
        '2008-01-20 00:00:00'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        'Cat''s in the Bag...',
        'Setelah situasi yang rumit di akhir episode pertama, Walter dan Jesse harus mencari cara untuk menangani konsekuensi tindakan mereka.',
        48.0,
        'https://www.example.com/breakingbad_2',
        '2008-01-27 00:00:00'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        'Winter Is Coming',
        'Pada masa yang dikenal sebagai "Musim Panjang", Lord Eddard Stark menerima penawaran dari Raja Robert Baratheon untuk menjadi Tangan Kanannya yang baru.',
        62.0,
        'https://www.example.com/gameofthrones_1',
        '2011-04-17 00:00:00'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        'The One Where Monica Gets a Roommate',
        'Rachel Green meninggalkan tunangannya di altar dan tiba-tiba muncul di apartemen teman masa kecilnya, Monica Geller, yang tinggal bersama Chandler Bing, Joey Tribbiani, dan Phoebe Buffay.',
        22.0,
        'https://www.example.com/friends_1',
        '1994-09-22 00:00:00'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        'Wolferton Splash',
        'Setelah kematian Raja George VI, putri sulungnya, Elizabeth, naik takhta sebagai Ratu Elizabeth II. Dia harus menghadapi tekanan politik, intrik, dan tuntutan pribadi yang berat.',
        57.0,
        'https://www.example.com/thecrown_1',
        '2016-11-04 00:00:00'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        'Chapter One: The Vanishing of Will Byers',
        'Pada tahun 1983, seorang bocah bernama Will Byers menghilang secara misterius di Hawkins, Indiana. Saat teman-temannya mencari tahu keberadaannya, mereka menemukan gadis misterius dengan kemampuan telekinetik.',
        48.0,
        'https://www.example.com/strangerthings_1',
        '2016-07-15 00:00:00'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        'Pilot',
        'Seorang dokumenter tentang kehidupan sehari-hari di kantor perusahaan Dunder Mifflin, Scranton, Pennsylvania, diikuti oleh seorang manajer yang aneh bernama Michael Scott dan karyawan-karyawannya yang unik.',
        23.0,
        'https://www.example.com/theoffice_1',
        '2005-03-24 00:00:00'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        'Diversity Day',
        'Setelah insiden kontroversial pada hari penerimaan, Michael Scott diwajibkan untuk menyelenggarakan "Hari Keanekaragaman" di kantor.',
        22.0,
        'https://www.example.com/theoffice_2',
        '2005-03-29 00:00:00'
    ),
    (
        'd35ae7cf-f812-4524-876b-7cae4d46f127',
        'A Study in Pink',
        'Dr. John Watson bertemu Sherlock Holmes, seorang detektif konsultan yang brilian tapi eksentrik. Mereka mulai bekerja sama untuk memecahkan serangkaian kasus misterius di London.',
        88.0,
        'https://www.example.com/sherlock_1',
        '2010-07-25 00:00:00'
    ),
    (
        'f8d81d60-b5c0-4ae8-a1d0-132beb7585ba',
        'Chapter 1: The Mandalorian',
        'Seorang pemburu bayaran Mandalorian menerima tugas rahasia yang membawanya ke luar batas-batas wilayah yang dikenal.',
        39.0,
        'https://www.example.com/mandalorian_1',
        '2019-11-12 00:00:00'
    ),
    (
        '1e32a378-6c89-4607-b981-abd702f129f0',
        'The End''s Beginning',
        'Geralt of Rivia, seorang pemburu monster yang dijuluki "Witcher", menyelamatkan seorang penyihir dari kemarahan para penduduk desa. Sementara itu, seorang penyihir muda bernama Yennefer menemukan takdirnya yang gelap.',
        61.0,
        'https://www.example.com/witcher_1',
        '2019-12-20 00:00:00'
    ),
    (
        '9cdcdd5f-1826-499e-ab11-a040d2c1ea2e',
        'The Original',
        'Di sebuah taman hiburan futuristik yang disebut Westworld, manusia dapat berinteraksi dengan android yang tak terhitung jumlahnya.',
        62.0,
        'https://www.example.com/westworld_1',
        '2016-10-02 00:00:00'
    );

INSERT INTO
    ULASAN
VALUES (
        'e1471b78-013f-4828-8a3e-381e67888232',
        'lily_tan',
        '2023-06-20 10:00:00',
        4.0,
        'Seri ini keren banget, plotnya seru dan karakter-karakternya bikin penasaran. Recomended banget buat ditonton!'
    ),
    (
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        'henry_clark',
        '2023-02-20 14:00:00',
        3.0,
        'Film ini bener-bener bikin klepek-klepek. Gak bisa berhenti nonton deh!'
    ),
    (
        '1e32a378-6c89-4607-b981-abd702f129f0',
        'mason_choi',
        '2023-08-05 11:00:00',
        5.0,
        'Serunya nggak bohong, tapi ada bagian-bagian yang agak lemot dan bikin ngerasa kurang puas.'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        'isabella_lee',
        '2023-02-25 08:00:00',
        4.0,
        'Aksi di film ini keren banget, efeknya bikin nganga! Layak nonton sih.'
    ),
    (
        '9cdcdd5f-1826-499e-ab11-a040d2c1ea2e',
        'emma_wilson',
        '2023-10-20 09:00:00',
        2.0,
        'Karakter-karakternya keren abis, bikin pengen tau lebih banyak tentang mereka.'
    ),
    (
        'f8d81d60-b5c0-4ae8-a1d0-132beb7585ba',
        'jackson_kim',
        '2023-05-25 16:00:00',
        5.0,
        'Ceritanya unik banget, nggak bisa ditebak. Beda dari yang lain!'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        'alice_johnson',
        '2023-03-20 12:00:00',
        3.0,
        'Dialognya ngena banget, aktingnya juga juara. Jadi salah satu favorit deh.'
    ),
    (
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        'david_smith',
        '2023-07-15 15:00:00',
        4.0,
        'Sayangnya, konsepnya menarik tapi eksekusinya kurang mantap.'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        'lily_tan',
        '2023-06-25 10:00:00',
        5.0,
        'Gue suka banget sama film ini. Seru banget nontonnya!'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        'henry_clark',
        '2023-02-25 14:00:00',
        2.0,
        'Walaupun ada kekurangan, tapi tetep seru dan layak ditonton.'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        'emma_wilson',
        '2023-10-25 09:00:00',
        4.0,
        'Sutradaranya keren banget, bikin adegan-adegan jadi dramatis banget.'
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        'jackson_kim',
        '2023-05-30 16:00:00',
        3.0,
        'Seri ini bener-bener deep, ngasih pandangan yang beda tentang hidup dan hubungan.'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        'mason_choi',
        '2023-08-15 11:00:00',
        5.0,
        'Adegan-adegan di film ini bikin tegang, sampe gak bisa berhenti ngebayangin.'
    ),
    (
        'e3b53e4e-d008-4d13-b74c-a0a1ae60e5df',
        'alice_johnson',
        '2023-03-25 12:00:00',
        4.0,
        'Premisnya menarik, tapi sayangnya pengembangan karakternya kurang.'
    ),
    (
        '9cdcdd5f-1826-499e-ab11-a040d2c1ea2e',
        'isabella_lee',
        '2023-03-05 08:00:00',
        3.0,
        'Humornya kocak banget, pas buat ngehibur.'
    ),
    (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        'david_smith',
        '2023-07-20 15:00:00',
        5.0,
        'Efek visualnya keren banget, bikin pengen nyemplung ke dalam ceritanya.'
    );

INSERT INTO
    DAFTAR_FAVORIT
VALUES (
        '2023-03-20 09:15:00',
        'lily_tan',
        'Movie Hits'
    ),
    (
        '2023-07-12 14:30:00',
        'emma_wilson',
        'Fantasy Playlist'
    ),
    (
        '2023-04-25 11:45:00',
        'david_smith',
        'Classic Movies'
    ),
    (
        '2023-02-12 16:20:00',
        'henry_clark',
        'Musical Favorites'
    ),
    (
        '2023-05-25 08:55:00',
        'isabella_lee',
        'Comedy Shows'
    ),
    (
        '2023-06-10 17:30:00',
        'jackson_kim',
        'Epic Fantasy'
    ),
    (
        '2023-01-20 13:40:00',
        'mason_choi',
        'Sci-Fi Adventures'
    ),
    (
        '2023-05-15 18:15:00',
        'emma_wilson',
        'Action Packed'
    ),
    (
        '2023-03-25 10:00:00',
        'isabella_lee',
        'Mind Benders'
    ),
    (
        '2023-07-15 12:45:00',
        'alice_johnson',
        'Mystery and Detective'
    ),
    (
        '2023-05-05 09:20:00',
        'henry_clark',
        'Star Wars Universe'
    ),
    (
        '2023-02-28 14:55:00',
        'lily_tan',
        'Thrilling Series'
    ),
    (
        '2023-06-01 16:30:00',
        'david_smith',
        'Royal Dramas'
    ),
    (
        '2023-06-25 11:10:00',
        'mason_choi',
        'Royal Dramas'
    ),
    (
        '2023-01-30 10:25:00',
        'jackson_kim',
        'Superhero Hits'
    ),
    (
        '2023-05-20 14:00:00',
        'alice_johnson',
        'Space Odyssey'
    );

INSERT INTO
    TAYANGAN_MEMILIKI_DAFTAR_FAVORIT
VALUES (
        'd217422a-30d3-4872-b1be-d842724f2cb8',
        '2023-03-20 09:15:00',
        'lily_tan'
    ),
    (
        '1e32a378-6c89-4607-b981-abd702f129f0',
        '2023-07-12 14:30:00',
        'emma_wilson'
    ),
    (
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        '2023-04-25 11:45:00',
        'david_smith'
    ),
    (
        'e3b53e4e-d008-4d13-b74c-a0a1ae60e5df',
        '2023-02-12 16:20:00',
        'henry_clark'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        '2023-05-25 08:55:00',
        'isabella_lee'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        '2023-06-10 17:30:00',
        'jackson_kim'
    ),
    (
        '9cdcdd5f-1826-499e-ab11-a040d2c1ea2e',
        '2023-01-20 13:40:00',
        'mason_choi'
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        '2023-05-15 18:15:00',
        'emma_wilson'
    ),
    (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        '2023-03-25 10:00:00',
        'isabella_lee'
    ),
    (
        'd35ae7cf-f812-4524-876b-7cae4d46f127',
        '2023-07-15 12:45:00',
        'alice_johnson'
    ),
    (
        'f8d81d60-b5c0-4ae8-a1d0-132beb7585ba',
        '2023-05-05 09:20:00',
        'henry_clark'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        '2023-02-28 14:55:00',
        'lily_tan'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        '2023-06-01 16:30:00',
        'david_smith'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        '2023-06-25 11:10:00',
        'mason_choi'
    ),
    (
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        '2023-01-30 10:25:00',
        'jackson_kim'
    ),
    (
        '9271fd7b-5d44-4570-b207-daa5a90e03ae',
        '2023-05-20 14:00:00',
        'alice_johnson'
    );

INSERT INTO
    RIWAYAT_NONTON
VALUES (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        'alice_johnson',
        '2023-03-20 09:15:00',
        '2023-03-20 10:45:00'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        'david_smith',
        '2023-07-12 14:30:00',
        '2023-07-12 16:00:00'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        'emma_wilson',
        '2023-04-25 11:45:00',
        '2023-04-25 13:15:00'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        'henry_clark',
        '2023-02-12 16:20:00',
        '2023-02-12 17:50:00'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        'isabella_lee',
        '2023-05-25 08:55:00',
        '2023-05-25 10:25:00'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        'jackson_kim',
        '2023-06-10 17:30:00',
        '2023-06-10 19:00:00'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        'lily_tan',
        '2023-01-20 13:40:00',
        '2023-01-20 15:10:00'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        'mason_choi',
        '2023-05-15 18:15:00',
        '2023-05-15 19:45:00'
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        'alice_johnson',
        '2023-03-25 10:00:00',
        '2023-03-25 11:30:00'
    ),
    (
        'd217422a-30d3-4872-b1be-d842724f2cb8',
        'david_smith',
        '2023-07-15 12:45:00',
        '2023-07-15 14:15:00'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        'emma_wilson',
        '2023-05-05 09:20:00',
        '2023-05-05 10:50:00'
    ),
    (
        'd35ae7cf-f812-4524-876b-7cae4d46f127',
        'henry_clark',
        '2023-02-28 14:55:00',
        '2023-02-28 16:25:00'
    ),
    (
        'f8d81d60-b5c0-4ae8-a1d0-132beb7585ba',
        'isabella_lee',
        '2023-06-05 20:10:00',
        '2023-06-05 21:40:00'
    ),
    (
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        'jackson_kim',
        '2023-06-22 17:00:00',
        '2023-06-22 18:30:00'
    ),
    (
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        'lily_tan',
        '2023-01-30 11:25:00',
        '2023-01-30 12:55:00'
    ),
    (
        '9271fd7b-5d44-4570-b207-daa5a90e03ae',
        'mason_choi',
        '2023-05-20 19:45:00',
        '2023-05-20 21:15:00'
    ),
    (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        'alice_johnson',
        '2023-04-05 15:30:00',
        '2023-04-05 17:00:00'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        'david_smith',
        '2023-07-20 08:10:00',
        '2023-07-20 09:40:00'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        'emma_wilson',
        '2023-05-10 12:00:00',
        '2023-05-10 13:30:00'
    ),
    (
        '9e8d7c6b-5a4b-3c2d-1e0f-9a8b7c6d5e4f',
        'henry_clark',
        '2023-03-05 17:55:00',
        '2023-03-05 19:25:00'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        'isabella_lee',
        '2023-06-15 09:40:00',
        '2023-06-15 11:10:00'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        'jackson_kim',
        '2023-07-02 18:20:00',
        '2023-07-02 19:50:00'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        'lily_tan',
        '2023-02-05 10:35:00',
        '2023-02-05 12:05:00'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        'mason_choi',
        '2023-05-30 20:00:00',
        '2023-05-30 21:30:00'
    );

INSERT INTO
    TAYANGAN_TERUNDUH
VALUES (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        'david_smith',
        '2023-02-15 09:45:00'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        'mason_choi',
        '2023-05-25 13:20:00'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        'isabella_lee',
        '2023-03-10 17:30:00'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        'henry_clark',
        '2023-02-28 08:10:00'
    ),
    (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        'jackson_kim',
        '2023-06-22 20:45:00'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        'alice_johnson',
        '2023-01-30 11:55:00'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        'lily_tan',
        '2023-04-25 14:00:00'
    ),
    (
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        'emma_wilson',
        '2023-06-15 19:30:00'
    ),
    (
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        'henry_clark',
        '2023-05-30 08:25:00'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        'lily_tan',
        '2023-03-25 10:40:00'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        'emma_wilson',
        '2023-05-20 10:15:00'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        'mason_choi',
        '2023-04-05 16:50:00'
    ),
    (
        '6f7c5e9d-4a2f-4e3b-8d2f-0e3a1d1e2b3c',
        'david_smith',
        '2023-07-20 12:35:00'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        'isabella_lee',
        '2023-01-20 14:30:00'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        'alice_johnson',
        '2023-06-05 21:00:00'
    ),
    (
        '0abd4d71-a1a5-4d69-a39d-4a1121ff0db4',
        'jackson_kim',
        '2023-05-15 19:00:00'
    ),
    (
        '1e2d3c4b-5a6b-7c8d-9e0f-1a2b3c4d5e6f',
        'emma_wilson',
        '2023-05-10 12:25:00'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        'mason_choi',
        '2023-04-18 18:55:00'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        'henry_clark',
        '2023-07-15 15:40:00'
    ),
    (
        '5d4c3b2a-1f2e-3d4c-5b6a-7c8d9e0f1a2b',
        'isabella_lee',
        '2023-03-05 18:20:00'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        'david_smith',
        '2023-06-10 19:45:00'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        'lily_tan',
        '2023-07-12 15:10:00'
    ),
    (
        '8e9f0a1b-2c3d-4e5f-6a7b-8c9d0e1f2a3b',
        'jackson_kim',
        '2023-01-25 11:35:00'
    ),
    (
        '05b0695d-039b-4f1e-94ba-f5a49c0c08b2',
        'alice_johnson',
        '2023-06-10 08:00:00'
    ),
    (
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        'alice_johnson',
        '2023-06-20 16:30:00'
    ),
    (
        '3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
        'lily_tan',
        '2023-05-05 09:55:00'
    ),
    (
        '1f6bb620-d8db-43ed-8911-c29c8a8a1383',
        'emma_wilson',
        '2023-02-05 11:20:00'
    ),
    (
        '706851cf-ebbc-4bbc-93e7-b5469d47b84d',
        'henry_clark',
        '2023-06-10 17:25:00'
    ),
    (
        '4d5e6f7a-8b9c-1d2e-3f4a-5b6c7d8e9f0a',
        'david_smith',
        '2023-02-12 17:05:00'
    ),
    (
        '3b4c5d6e-7f8a-9b0c-1d2e-3f4a5b6c7d8e',
        'isabella_lee',
        '2023-07-02 18:40:00'
    ),
	(
		'706851cf-ebbc-4bbc-93e7-b5469d47b84d',
		'alice_johnson',
		'2024-05-19 03:09:00'
	);