# RAYA: Tetap Terhubung

Aplikasi komunikasi pribadi berbasis Flutter yang menggabungkan chat terenkripsi end-to-end, berbagi titik lokasi dua arah yang disetujui kedua pihak, dan peta publik dengan status singkat yang berlaku 8 jam.

## Status

Tahap pengembangan. Lihat [PRD](docs/PRD_v0.3.md) untuk ruang lingkup dan [DESIGN](docs/DESIGN.md) untuk panduan visual.

## Teknologi

- Flutter (Dart) untuk Android dan iOS
- Supabase (PostgreSQL, Storage, Realtime, Edge Functions)
- Firebase Cloud Messaging
- Resend untuk email OTP
- Google Maps Platform
- Library kriptografi teruji (libsodium atau Signal Protocol)

## Menjalankan Secara Lokal

1. Salin `config.example.json` menjadi `config.json` dan isi nilainya.
2. Jalankan `flutter pub get`.
3. Jalankan `flutter run --dart-define-from-file=config.json`.

Jangan commit `config.json`. Rahasia server tidak pernah disimpan di repositori ini.

## Keamanan

Jika menemukan celah keamanan, jangan buka issue publik. Hubungi pemilik repositori secara langsung.

## Lisensi

Hak cipta dilindungi. Belum ada lisensi publik.
