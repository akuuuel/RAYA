# Arsitektur Proyek RAYA

Dokumen ini merupakan panduan arsitektur teknis resmi untuk pengembangan aplikasi RAYA.

---

## 1. Prinsip Utama

1. **Feature-First Architecture:** Kode dipisahkan berdasarkan domain fungsional fitur.
2. **Kemandirian Lapisan (Separation of Concerns):** Pemisahan tegas antara UI (Presentation), Logika Bisnis (Domain/Application), dan Sumber Data (Data/Repository).
3. **Zero-Trust Client:** Kode klien tidak pernah menyimpan rahasia backend (`service_role`, kunci Resend, kunci Firebase Admin).
4. **Hanya Tema Gelap:** Seluruh styling mengacu ke token resmi di `core/theme/` ([DESIGN.md](file:///c:/RAYA/DESIGN.md)).

---

## 2. Struktur Direktori

```text
lib/
├── core/
│   ├── config/              # Runtime config (AppConfig via --dart-define-from-file)
│   ├── theme/               # Token desain (app_colors, app_text_styles, app_spacing, app_theme)
│   ├── error/               # Model error, failures, dan exception handling
│   ├── network/             # Inisialisasi client Supabase
│   └── utils/               # Formatter, validasi usia, helper tanggal
├── shared/
│   └── widgets/             # Komponen bersama (PrimaryButton, AppTextField, OtpInput, dll.)
└── features/
    ├── auth/                # FR-01 - FR-05 (Email OTP, Usia, Hapus Akun)
    │   ├── data/            # AuthRepository, Remote DataSource
    │   ├── domain/          # Entitas User, UserSession, Failure
    │   └── presentation/    # Layar Onboarding, Login, OTP, Controllers
    ├── profile/             # FR-03, FR-04 (Lengkapi profil, status usia 18+)
    ├── chat/                # FR-09 - FR-19 (Fase 2 & 3)
    ├── location/            # FR-20 - FR-28 (Fase 3: Pantau Lokasi 18+)
    ├── public_map/          # FR-29 - FR-40 (Fase 4: Peta Publik, Status 8 Jam)
    └── contacts/            # FR-06 - FR-08 (Fase 2)
```

---

## 3. Standar State Management (Riverpod)

Proyek ini menggunakan pustaka `flutter_riverpod` dengan standar berikut:

1. **Gaya Penulisan Konsisten:**
   - Gunakan `Notifier` / `AsyncNotifier` (atau `StateNotifier`) untuk state yang memiliki mutasi atau siklus hidup asinkron.
   - Provider dideklarasikan sebagai konstanta `final` tingkat atas di berkas controller terkait.
2. **Akses di Widget:**
   - Widget yang membutuhkan reaktivitas menggunakan `ConsumerWidget` atau `ConsumerStatefulWidget`.
   - Gunakan `ref.watch(provider)` di dalam metode `build()` untuk rebuild otomatis saat state berubah.
   - Gunakan `ref.read(provider.notifier)` di dalam event handler (misalnya `onPressed`) untuk memicu aksi, bukan di dalam `build()`.
3. **Pemisahan Logika:**
   - Widget tidak boleh memanggil API Supabase/Firebase secara langsung. Seluruh interaksi wajib melalui `Repository` yang disediakan via provider.

---

## 4. Konfigurasi Lingkungan & Keamanan

- **Konfigurasi Klien:** Menggunakan `--dart-define-from-file=config.json`.
- **Git Hygiene:** `config.json` di-ignore dari repositori Git. Template konfigurasi tersedia di `config.example.json`.
- **Data Sensitif:**
  - Kunci enkripsi privat tidak pernah keluar dari perangkat.
  - Tanggal lahir disimpan secara minimal di profil untuk menentukan status `is_adult`.
  - Pengecekan usia 18 tahun dan validasi OTP wajib dieksekusi di Supabase Edge Function dan dilindungi Row Level Security (RLS).
