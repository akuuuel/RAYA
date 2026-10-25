# DESIGN.md: Panduan UI/UX

**Nama Produk:** RAYA
**Tagline:** Tetap Terhubung
**Versi:** 0.1 (Draft)
**Tanggal:** 26 Oktober 2026
**Referensi visual:** Tiga layar onboarding, login, dan verifikasi email dengan tema gelap dan aksen ungu gradien.
**Platform:** Flutter (Android dan iOS)
**Pendamping:** PRD v0.3

> Catatan: nilai warna dan ukuran di dokumen ini adalah perkiraan dari gambar referensi. Angka final perlu disesuaikan di tahap desain (Figma) dan diuji langsung di perangkat.

---

## 1. Tujuan dan Prinsip Desain

Desain aplikasi ini mengikuti gaya visual referensi: latar gelap, aksen ungu yang bercahaya, komponen membulat, dan ilustrasi 3D bergaya kaca. Tujuannya membuat aplikasi terasa modern, tenang, dan dapat dipercaya, sesuai dengan fungsinya sebagai aplikasi komunikasi pribadi dan berbagi lokasi.

**Prinsip utama:**

1. **Tenang dan fokus.** Latar gelap dan aksen ungu dipakai untuk mengarahkan perhatian, bukan untuk ramai. Satu layar satu tujuan.
2. **Privasi terlihat jelas.** Elemen yang berkaitan dengan lokasi, enkripsi, dan status berbagi harus mudah dikenali lewat ikon dan warna khusus, sehingga pengguna selalu tahu kondisi datanya.
3. **Ramah sentuhan.** Tombol besar, jarak antar elemen lega, dan input mudah diisi di layar kecil.
4. **Konsisten.** Pola tombol, input, dan kartu sama di seluruh aplikasi.
5. **Dapat diakses.** Kontras teks dijaga, ukuran font mengikuti pengaturan sistem, dan semua ikon punya label.

## 2. Tema

- **Hanya tema gelap** pada versi pertama. Tidak ada mode terang di MVP.
- Latar utama hampir hitam dengan sentuhan ungu sangat gelap, bukan hitam murni, agar lebih nyaman di mata.
- Cahaya ungu lembut (blur besar) muncul di sudut atas layar sebagai dekorasi latar. Efek ini hanya dipakai di layar onboarding, login, dan verifikasi, bukan di layar yang padat data seperti chat dan peta.

## 3. Warna

Nilai berikut adalah perkiraan dari referensi.

| Token | Perkiraan Hex | Penggunaan |
|-------|---------------|------------|
| `background` | `#07050F` | Latar utama layar |
| `surface` | `#15121F` | Kartu, input field, bottom sheet |
| `surfaceBorder` | `#2A2538` | Garis tepi input dan kartu |
| `primary` | `#7C3AED` | Tombol utama, ikon aktif, tautan |
| `primaryDeep` | `#5B21B6` | Ujung gradien tombol utama |
| `primaryGlow` | `#A78BFA` | Cahaya latar, highlight, judul berwarna |
| `textPrimary` | `#FFFFFF` | Judul dan teks utama |
| `textSecondary` | `#B8B3C9` | Subjudul, placeholder, teks pendukung |
| `textMuted` | `#7D7790` | Keterangan kecil, label nonaktif |
| `success` | `#22C55E` | Pesan terkirim, verifikasi berhasil, status aktif |
| `warning` | `#F59E0B` | Peringatan masa berlaku status, batas usia |
| `danger` | `#EF4444` | Kesalahan, laporan, tombol hapus |
| `locationActive` | `#34D399` | Indikator berbagi lokasi aktif (titik pulsa) |

**Gradien utama** (tombol dan aksen): dari `primary` ke `primaryDeep`, arah kiri ke kanan atau atas ke bawah.

**Aturan warna:**
- Ungu dipakai untuk aksi dan identitas, bukan untuk teks panjang.
- Warna status (hijau, kuning, merah) hanya untuk makna status, tidak untuk dekorasi.
- Kontras teks terhadap latar minimal 4.5:1 untuk teks biasa dan 3:1 untuk teks besar.

## 4. Tipografi

- **Keluarga font:** sans-serif geometris dan bersih. Rekomendasi: *Plus Jakarta Sans* atau *Manrope*, dimuat lewat paket `google_fonts` atau sebagai aset lokal.
- **Fallback:** `sans-serif` bawaan sistem.

| Gaya | Ukuran | Berat | Penggunaan |
|------|--------|-------|------------|
| `displayLarge` | 32 sp | Bold (700) | Judul layar onboarding |
| `headlineMedium` | 24 sp | Bold (700) | Judul layar login dan verifikasi |
| `titleMedium` | 16 sp | Semibold (600) | Nama kontak, judul kartu |
| `bodyLarge` | 16 sp | Regular (400) | Isi pesan, teks utama |
| `bodyMedium` | 14 sp | Regular (400) | Subjudul, deskripsi |
| `labelLarge` | 16 sp | Semibold (600) | Teks tombol |
| `labelSmall` | 12 sp | Medium (500) | Waktu, keterangan kecil |

**Aturan tipografi:**
- Judul pendek dan rata tengah di layar autentikasi. Rata kiri di layar isi.
- Kata kunci di judul boleh memakai warna `primaryGlow` atau gradien, seperti pada "Nexa Mind" di referensi. Hanya satu frasa per layar.
- Ukuran font mengikuti pengaturan sistem (`textScaler`). Layout tidak boleh pecah saat ukuran font diperbesar.

## 5. Spasi, Grid, dan Radius

**Skala spasi** (kelipatan 4): 4, 8, 12, 16, 20, 24, 32, 40, 48.

- Margin horizontal layar: 24 dp.
- Jarak antar input di form: 16 dp.
- Jarak antar blok besar: 32 dp.
- Tinggi area aman di bawah tombol utama: sesuai `SafeArea`.

**Radius sudut:**

| Komponen | Radius |
|----------|--------|
| Tombol utama | 16 dp |
| Input field | 14 dp |
| Kartu | 20 dp |
| Bottom sheet | 28 dp (sudut atas) |
| Avatar dan tombol sosial | Lingkaran penuh |
| Badge lokasi di peta | Pil (radius penuh) |

## 6. Komponen

### 6.1 Tombol Utama
- Lebar penuh, tinggi 56 dp.
- Latar gradien `primary` ke `primaryDeep`, teks putih, radius 16 dp.
- Status: normal, ditekan (sedikit lebih gelap, skala 0,98), nonaktif (opasitas 40%), memuat (indikator putar menggantikan teks).
- Hanya satu tombol utama per layar.

### 6.2 Tombol Sekunder dan Teks
- Tombol sekunder: latar `surface`, garis tepi `surfaceBorder`, teks putih.
- Tombol teks (contoh "Skip", "Lewati"): teks `textSecondary`, tanpa latar.
- Tautan (contoh "Sign Up", "Resend"): warna `primaryGlow`, dapat diketuk, ukuran tidak kurang dari 44 dp area sentuh.

### 6.3 Input Field
- Tinggi 56 dp, latar `surface`, garis tepi `surfaceBorder`, radius 14 dp.
- Ikon di kiri (email, gembok), ikon mata di kanan untuk kata sandi.
- Saat fokus: garis tepi berubah menjadi `primary` dengan cahaya lembut.
- Saat error: garis tepi `danger` dengan teks pesan di bawah field.
- Label di atas field dengan `bodyMedium`, bukan hanya placeholder.

### 6.4 Input Kode OTP (6 Digit)
- Enam kotak terpisah, masing-masing sekitar 44 x 52 dp, radius 12 dp, latar `surface`.
- Fokus otomatis pada kotak pertama. Pindah otomatis ke kotak berikutnya saat diisi.
- Mendukung paste penuh 6 digit dan `autofill` dari SMS atau email jika tersedia (`AutofillHints.oneTimeCode`).
- Kotak terisi memakai garis tepi `primary`. Kotak salah memakai `danger`.
- Setelah 6 digit terisi, tombol "Verifikasi" aktif otomatis.
- Tautan "Kirim ulang" nonaktif selama hitung mundur (misalnya 60 detik), lalu menampilkan hitung mundur.

### 6.5 Checkbox dan Toggle
- Checkbox kecil dengan sudut membulat, warna terisi `primary`. Contoh: "Ingat saya".
- Toggle untuk pengaturan (tampil publik, berbagi lokasi): warna aktif `primary` atau `locationActive` untuk pengaturan lokasi.

### 6.6 Tombol Login Sosial
- Lingkaran berdiameter 52 dp, latar putih, ikon di tengah.
- **Catatan:** versi awal hanya memakai login email OTP sesuai PRD v0.3. Tombol sosial tidak dipakai di MVP. Komponen ini disimpan untuk versi berikutnya bila diperlukan.

### 6.7 Indikator Halaman (Dot Pagination)
- Titik kecil 8 dp. Titik aktif memanjang menjadi pil 24 dp dengan warna `primary`.
- Hanya di onboarding.

### 6.8 Kartu dan Bottom Sheet
- Kartu: latar `surface`, radius 20 dp, padding 16 dp, tanpa bayangan keras.
- Bottom sheet untuk aksi tambahan (pilih durasi pantau, pilih masa berlaku status, opsi laporan).
- Pegangan (handle) kecil di atas bottom sheet.

### 6.9 Badge Lokasi di Peta Publik
- Pil berisi avatar kecil, username atau nama samaran, dan ikon status.
- Latar `surface` dengan garis tepi `primary` tipis, atau cahaya `primaryGlow` untuk badge yang punya status aktif.
- Ukuran tap minimal 44 dp. Badge tidak menampilkan koordinat atau alamat.
- Di atas peta, badge bersifat tetap dan tidak bergerak mengikuti kursor pengguna.

### 6.10 Indikator Berbagi Lokasi
- Titik kecil `locationActive` dengan animasi pulsa lembut, ditampilkan di bilah atas dan di ikon tab Pantau.
- Pada bilah status perangkat, indikator harus tampak tanpa mengganggu (sesuai FR-25 di PRD).

### 6.11 Bilah Navigasi Bawah (5 Tab)
- Tinggi sekitar 72 dp (termasuk area aman), latar `surface` dengan sedikit blur, sudut atas membulat.
- Ikon garis dengan label kecil di bawah. Tab aktif memakai ikon terisi dan warna `primary` atau `primaryGlow`.
- Badge angka untuk pesan baru dan permintaan kontak pada tab Chat dan Kontak.
- Lima tab sesuai PRD: Chat, Pantau, Sekitar, Kontak, Profil.

### 6.12 Ilustrasi
- Gaya 3D kaca (glassmorphism) dengan gradien ungu, cahaya tepi, dan elemen kartu transparan.
- Dipakai untuk onboarding, halaman kosong, dan layar verifikasi. Ukuran sekitar 60 hingga 70 persen lebar layar.
- Ilustrasi harus memakai aset buatan sendiri atau aset berlisensi. Jangan menyalin ilustrasi dari sumber referensi.

## 7. Layar Utama

### 7.1 Onboarding (3 layar)
- Latar gelap dengan cahaya ungu di sudut atas.
- Judul di bagian bawah, rata kiri, dengan kata kunci berwarna `primaryGlow`.
- Satu kalimat deskripsi singkat di bawah judul.
- Dot pagination di atas tombol "Next".
- Tombol "Next" sebagai tombol utama dan "Skip" sebagai tombol teks di bawahnya.
- Pada layar terakhir, "Next" berubah menjadi "Mulai".

**Teks yang disarankan (Bahasa Indonesia):**
1. "Selamat datang di *RAYA*. Chat, berbagi lokasi, dan kabar singkat, dalam satu tempat." (Tagline: "Tetap Terhubung" dapat dipakai sebagai judul layar pertama.)
2. "Pesanmu terenkripsi. Hanya kamu dan penerimamu yang bisa membacanya."
3. "Kamu yang memutuskan. Lokasi hanya dibagikan saat kamu setuju."

### 7.2 Masuk (Login dengan Email)
- Judul "Selamat datang kembali" atau "Masuk dengan email", subjudul singkat.
- Input email dengan ikon amplop.
- Tombol utama "Kirim kode". Tidak ada input kata sandi, sesuai alur OTP.
- Tautan di bawah: "Belum punya akun? Daftar".
- Pada pendaftaran, tambahan input tanggal lahir dengan penjelasan singkat mengapa diperlukan (lihat 7.4).

### 7.3 Verifikasi Email (OTP)
- Ilustrasi di bagian atas (gembok kaca dengan kartu email).
- Judul "Verifikasi email Anda", subjudul menampilkan alamat email yang dituju.
- Enam kotak OTP (lihat 6.4).
- Tombol utama "Verifikasi".
- Di bawah: "Tidak menerima kode? Kirim ulang" dengan hitung mundur.
- Tombol kembali untuk mengganti alamat email.
- Pesan kesalahan jelas: "Kode salah. Sisa 4 percobaan." Setelah batas percobaan habis, tampilkan jeda dan penjelasan.

### 7.4 Pendaftaran dan Tanggal Lahir
- Input tanggal lahir memakai pemilih tanggal, bukan input bebas.
- Teks penjelasan di bawah field: "Fitur berbagi lokasi langsung hanya tersedia untuk usia 18 tahun ke atas."
- Jika pengguna belum 18 tahun, tampilkan informasi tanpa menghentikan pendaftaran: fitur chat tetap bisa dipakai.

### 7.5 Chat
- Daftar percakapan dengan avatar, nama, pratinjau pesan, waktu, dan jumlah pesan belum dibaca.
- Ruang chat: gelembung pesan dengan latar `surface` (pesan diterima) dan gradien `primary` (pesan terkirim).
- Indikator status pesan: terkirim, diterima, terbaca.
- Indikator "sedang mengetik" di atas kolom input.
- Ikon kunci kecil di header chat menandakan enkripsi end-to-end aktif. Ketuk untuk melihat kode verifikasi keamanan.
- Kolom input dengan tombol lampiran, kolom teks, dan tombol mikrofon. Tahan tombol mikrofon untuk merekam, geser ke kiri untuk membatalkan.

### 7.6 Pantau Lokasi
- Peta gelap dengan gaya peta yang diatur ke tema gelap (Google Maps style JSON).
- Penanda diri sendiri dengan avatar dan titik biru atau ungu.
- Penanda kontak yang dipantau dengan avatar dan waktu pembaruan terakhir.
- Panel bawah (bottom sheet) menampilkan daftar kontak dan sisa durasi berbagi.
- Tombol "Hentikan berbagi" selalu terlihat saat ada sesi aktif.

### 7.7 Sekitar (Peta Publik)
- Peta gelap dengan badge lokasi yang sudah disamarkan (lihat 6.9).
- Tombol filter radius (1 km, 5 km, 10 km) di bagian atas.
- Tombol utama "Pasang status" mengambang di bagian bawah, tetap terlihat.
- Saat badge diketuk, bottom sheet terbuka dan menampilkan status, catatan, foto, masa berlaku yang tersisa, dan kolom komentar (hanya untuk kontak terhubung).
- Jika pengguna belum mengaktifkan tampil publik, layar menampilkan penjelasan singkat dan tombol aktivasi, bukan peta kosong.
- Pesan pada status yang habis: "Status ini sudah berakhir."

### 7.8 Kontak
- Daftar kontak dengan avatar dan status (terhubung, menunggu, diblokir).
- Tombol tambah kontak sebagai tombol mengambang atau ikon di header.
- Tab kecil atau segmen untuk memisahkan "Kontak" dan "Permintaan".

### 7.9 Profil dan Pengaturan
- Kartu profil di bagian atas dengan foto, nama, dan username.
- Daftar pengaturan dengan ikon dan teks: privasi, usia, notifikasi, cadangan chat, bantuan, keluar.
- Bagian "Privasi" memuat toggle tampil publik dan daftar siapa yang sedang memantau.

## 8. Alur dan Pola Interaksi

- **Satu tujuan per layar.** Hindari menumpuk banyak tombol utama.
- **Konfirmasi untuk tindakan berisiko.** Menghentikan berbagi lokasi, menghapus status, dan menghapus akun harus meminta konfirmasi.
- **Umpan balik langsung.** Setiap ketukan memberi respons visual dalam 100 ms. Operasi yang lebih lama menampilkan indikator memuat.
- **Kesalahan dijelaskan dengan bahasa sederhana** dan menyarankan langkah berikutnya. Contoh: "Koneksi terputus. Pesan akan terkirim saat jaringan kembali."
- **Keadaan kosong dirancang.** Setiap daftar kosong (chat, kontak, peta publik) memiliki ilustrasi kecil dan satu tombol ajakan.
- **Lokasi selalu jelas.** Sebelum meminta izin lokasi, aplikasi menjelaskan alasannya. Izin hanya diminta saat fitur dipakai pertama kali.

## 9. Gerakan dan Animasi

| Elemen | Gerakan | Durasi |
|--------|---------|--------|
| Perpindahan layar | Geser horizontal (standar platform) | 250 ms |
| Tombol ditekan | Skala 0,98 dan kembali | 120 ms |
| Dot onboarding | Pil memanjang | 200 ms |
| Indikator berbagi lokasi | Pulsa lembut | 1,5 detik, berulang |
| Bottom sheet | Naik dengan pegas ringan | 300 ms |
| Ilustrasi onboarding | Melayang halus (opsional) | 3 detik, berulang |

**Aturan gerakan:**
- Hormati pengaturan "kurangi gerakan" di sistem. Jika aktif, matikan pulsa dan melayang.
- Animasi tidak boleh menghalangi pengguna dari mengetuk elemen.

## 10. Aksesibilitas

- Kontras teks dan ikon sesuai bagian 3.
- Area sentuh minimal 44 x 44 dp.
- Semua ikon punya `semanticsLabel` untuk pembaca layar.
- Font mengikuti `textScaler` sistem hingga 200 persen tanpa memotong teks.
- Warna tidak menjadi satu-satunya pembeda status. Gunakan ikon dan teks pendukung, misalnya "Berbagi aktif" dengan titik hijau.
- Dukungan `autofill` dan `oneTimeCode` pada input OTP.

## 11. Struktur Kode Tema (Flutter)

Contoh struktur tema yang disarankan:

```
lib/
  core/
    theme/
      app_colors.dart      // token warna (bagian 3)
      app_text_styles.dart // gaya teks (bagian 4)
      app_spacing.dart     // skala spasi dan radius (bagian 5)
      app_theme.dart       // ThemeData gelap
  shared/
    widgets/
      primary_button.dart
      app_text_field.dart
      otp_input.dart
      location_badge.dart
      location_active_dot.dart
      app_bottom_nav.dart
```

**Aturan implementasi:**
- Semua warna dan ukuran diambil dari token, tidak ditulis langsung di widget.
- `ThemeData` diatur dengan `brightness: Brightness.dark` dan `useMaterial3: true`.
- Komponen bersama ditaruh di `shared/widgets` agar konsisten di seluruh layar.

## 12. Alat dan Proses Desain

- **Desain di Figma:** buat satu berkas dengan halaman Tokens, Components, dan Screens. Token warna dan teks diekspor ke `app_colors.dart` dan `app_text_styles.dart`.
- **Prototipe:** hubungkan alur onboarding, login, OTP, dan tab utama sebelum mulai membuat kode.
- **Uji di perangkat:** cek kontras di bawah sinar matahari, ukuran font besar, dan mode kurangi gerakan.
- **Urutan pengerjaan:** mengikuti rencana fase di PRD. Tema dan komponen dasar dibuat di Fase 1, sebelum layar chat dan peta.

## 13. Pertanyaan Terbuka

1. Nama aplikasi sudah ditetapkan sebagai RAYA dengan tagline "Tetap Terhubung". Apakah logo sudah tersedia? Ini memengaruhi warna aksen dan gaya ilustrasi.
2. Apakah ilustrasi dibuat sendiri, dipesan dari desainer, atau memakai aset berlisensi?
3. Apakah font Plus Jakarta Sans atau Manrope sudah disetujui?
4. Apakah gaya peta gelap perlu dikustomisasi agar sesuai warna aksen?
5. Apakah onboarding perlu versi bahasa Inggris, atau cukup Bahasa Indonesia pada tahap awal?
