# RAYA: Tetap Terhubung

Aplikasi komunikasi pribadi berbasis Flutter yang memprioritaskan privasi tinggi, kepatuhan terhadap **UU Perlindungan Data Pribadi (UU PDP No. 27/2022)**, chat terenkripsi end-to-end (E2EE), berbagi titik lokasi dua arah khusus dewasa (18+) yang disetujui kedua pihak, dan peta publik dengan status singkat yang berlaku 8 jam.

---

## 🚀 Fitur Utama & Kepatuhan PRD v0.3

- **Tema Gelap OLED (FR-01):** Palet warna ungu gelap (`#08060F`, `#120E24`, `#7C3AED`, `#A78BFA`) hemat daya baterai.
- **Autentikasi Email OTP (FR-02):** Akses tanpa kata sandi via email OTP 6-digit dengan rate-limiting dan hashing SHA-256.
- **Batas Usia 18+ (FR-04, FR-20):** Fitur pelacakan lokasi dan peta publik terkunci otomatis jika pengguna berusia di bawah 18 tahun.
- **Hapus Akun Permanen (FR-05):** Menghapus seluruh profil, relasi, dan jejak dari server Supabase seketika.
- **Chat Terenkripsi End-to-End (FR-09 s/d FR-18):** Pertukaran kunci publik Diffie-Hellman MODP 1536-bit (RFC 3526), kode keamanan 60-digit (*Safety Number*), dan penghapusan pesan untuk semua pihak (< 15 menit).
- **Pantau Lokasi 2 Arah (FR-21 s/d FR-28):** Berbagi lokasi dengan izin mutual, pilihan durasi (1 jam, 4 jam, 8 jam, manual), indikator pulsa hijau berkedip (`#34D399`), dan pembersihan koordinat live otomatis saat sesi berakhir.
- **Peta Publik & Status 8 Jam (FR-29 s/d FR-40):** Penyamaran koordinat acak minimal 300 meter (FR-30), badge status berbentuk pil interaktif, komentar hanya untuk kontak terhubung (FR-35), dan penghapusan otomatis setelah 8 jam.
- **Sistem Moderasi & Laporan (FR-41 s/d FR-44):** Pelaporan dengan 6 kategori pelanggaran, penandaan prioritas tinggi (*Ancaman Kekerasan* & *Perlindungan Anak*), serta persetujuan eksplisit dekripsi bukti chat E2EE.
- **Preferensi Notifikasi & Mode Privat (FR-45 s/d FR-48):** Mode privat menyembunyikan nama pengirim & cuplikan teks di preview notifikasi sistem, kendali getaran/suara, dan jam tenang (*Quiet Hours*).

---

## 🛠️ Arsitektur Teknologi

- **Frontend:** Flutter SDK (Dart) untuk Android dan iOS
- **State Management:** Flutter Riverpod 2.6
- **Backend & Database:** Supabase (PostgreSQL 15 dengan Row Level Security)
- **Edge Functions:** Deno runtime (`request-otp`, `verify-otp`, `delete-account`)
- **Email Service:** Resend API untuk pengiriman OTP
- **Kriptografi:** Diffie-Hellman MODP 1536-bit (RFC 3526) + AES-CTR / HMAC SHA-256

---

## 📂 Struktur Proyek

```
c:\RAYA\
├── config.example.json           # Template konfigurasi environment
├── lib/
│   ├── core/                     # Tema, spacing, token warna, kriptografi & konfigurasi
│   │   ├── config/app_config.dart
│   │   ├── crypto/crypto_service.dart
│   │   └── theme/
│   ├── features/
│   │   ├── auth/                 # Login, verifikasi OTP, lengkapi profil 18+
│   │   ├── chat/                 # Obrolan E2EE, safety numbers, gelembung pesan
│   │   ├── contacts/             # Tambah kontak, permintaan pertemanan, blokir
│   │   ├── explore/              # Peta publik, status 8 jam, badge penyamaran 300m
│   │   ├── moderation/           # Aduan pelanggaran, dialog bukti E2EE, preferensi notifikasi
│   │   ├── navigation/           # Shell navigasi 5 tab
│   │   ├── profile/              # Profil pengguna, verifikasi batas usia, hapus akun
│   │   └── tracking/             # Pantau lokasi 2 arah, durasi, indikator pulsa hijau
│   ├── shared/                   # Widget terpakai ulang (PrimaryButton, AppTextField, dll)
│   └── main.dart                 # Titik masuk aplikasi
├── supabase/
│   ├── functions/                # Deno Edge Functions
│   │   ├── delete-account/
│   │   ├── request-otp/
│   │   └── verify-otp/
│   └── migrations/               # Skema database & RLS PostgreSQL
│       ├── 20261026000001_contacts_schema.sql
│       ├── 20261026000002_chat_messages_schema.sql
│       ├── 20261026000003_location_tracking_schema.sql
│       ├── 20261026000004_public_statuses_schema.sql
│       └── 20261026000005_moderation_reports_schema.sql
└── test/
    └── widget_test.dart          # Pengujian unit & widget komprehensif
```

---

## 🏃 Menjalankan Aplikasi

### 1. Mode Lokal / Demo (Tanpa Dependensi Backend)
Secara default, aplikasi berjalan dalam mode mock yang terisolasi untuk memudahkan peninjauan antarmuka dan alur:
```bash
flutter pub get
flutter run
```

### 2. Mode Produksi / Terhubung ke Supabase
1. Salin `config.example.json` menjadi `config.json`:
   ```bash
   cp config.example.json config.json
   ```
2. Isi `SUPABASE_URL` dan `SUPABASE_ANON_KEY` proyek Anda, lalu atur `"USE_MOCK": false`.
3. Jalankan aplikasi:
   ```bash
   flutter run --dart-define-from-file=config.json
   ```

### 3. Menjalankan Pengujian
Untuk memverifikasi seluruh fungsionalitas:
```bash
flutter test
```

---

## 🔒 Kebijakan Keamanan & Kepatuhan Hukum

Aplikasi ini tunduk pada ketentuan **Undang-Undang No. 27 Tahun 2022 tentang Pelindungan Data Pribadi (UU PDP)** Republik Indonesia. Seluruh pemrosesan data geolokasi memerlukan izin eksplisit dan dapat dicabut sewaktu-waktu oleh pengguna tanpa meninggalkan jejak riwayat perjalanan.
