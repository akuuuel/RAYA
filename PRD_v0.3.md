# Product Requirements Document (PRD)

**Nama Produk:** RAYA
**Tagline:** Tetap Terhubung
**Versi:** 0.3 (Draft)
**Tanggal:** 26 Oktober 2026
**Pengembang:** Satu orang (pemilik produk merangkap pengembang)
**Status:** Draft untuk pengembangan bertahap

**Perubahan dari v0.2:**

| Topik | v0.2 | v0.3 |
|-------|------|------|
| Login | Nomor telepon dan OTP | OTP lewat email melalui Resend |
| Protokol enkripsi | Belum ditentukan | Library yang sudah teruji |
| Masa berlaku status publik | Pilihan 1 jam, 24 jam, atau 7 hari | Tetap 8 jam, lalu disembunyikan otomatis |
| Status publik | Tidak dapat dikomentari (pertanyaan terbuka) | Dapat dikomentari oleh kontak yang sudah saling terhubung |
| Batas usia | Tidak ada | Minimal 18 tahun untuk membagikan lokasi langsung |
| Penanganan laporan | Moderasi oleh pemilik produk | Laporan ditangani segera oleh tim |

---

## 1. Ringkasan

Aplikasi komunikasi pribadi berbasis Flutter yang menggabungkan chat terenkripsi end-to-end (teks, foto, pesan suara), berbagi titik lokasi dua arah yang disetujui kedua pihak (khusus pengguna berusia 18 tahun ke atas), dan peta publik tempat pengguna memasang status singkat yang berlaku 8 jam, terhubung dengan badge lokasi. Target awal adalah pengguna di Indonesia. Pengembangan dilakukan bertahap dengan biaya nol untuk tahap ini.

## 2. Latar Belakang dan Masalah

- Pengguna memakai beberapa aplikasi terpisah untuk chat, berbagi lokasi, dan memberi kabar kondisi mereka.
- Berbagi lokasi di aplikasi chat umum sering bersifat satu arah dan sulit dihentikan dengan jelas.
- Belum ada cara sederhana untuk membagikan kabar singkat ("sedang di kafe ini", "lagi antre di sini") kepada orang di sekitar tanpa membuka data pribadi.

## 3. Tujuan Produk

| No | Tujuan | Indikator Keberhasilan (contoh) |
|----|--------|-------------------------------|
| 1 | Menyediakan chat terenkripsi end-to-end yang lengkap (teks, foto, voice note) | 70% pesan berupa teks, foto, atau voice note dalam 30 hari pertama |
| 2 | Memungkinkan berbagi lokasi yang aman dan terkontrol | 50% pasangan kontak aktif menyetujui pantau lokasi |
| 3 | Menghadirkan peta publik dengan status singkat yang aman | Minimal 20% pengguna aktif memasang status, dengan rasio laporan tetap rendah |

## 4. Target Pengguna

- **Wilayah:** Indonesia (tahap awal).
- **Usia:**
  - Seluruh pengguna dapat mendaftar dan chat.
  - Fitur berbagi lokasi langsung (pantau lokasi) hanya untuk pengguna berusia 18 tahun ke atas.
- **Pengguna utama:** orang dewasa yang ingin berkomunikasi dan berbagi lokasi dengan kontak terpercaya, seperti keluarga, pasangan, teman dekat, atau rekan.
- **Pengguna sekunder:** orang yang ingin membagikan kabar singkat kepada orang di sekitarnya di peta publik.

**Persona singkat:**
- *Rina (28), karyawan:* ingin memberi tahu orang tuanya bahwa ia sudah sampai di kantor tanpa harus menelepon.
- *Budi (24), mahasiswa:* ingin tahu di mana temannya berkumpul di kafe, dan memasang status "lagi ngerjain tugas di sini, colokan masih ada" di peta publik agar orang lain bisa mencari tempat yang sama.

## 5. Keputusan Produk Tahap Ini

| Topik | Keputusan |
|-------|-----------|
| Pengembang dan tanggung jawab | Pemilik produk merangkap pengembang dan penanggung jawab utama. Penanganan laporan dilakukan oleh tim yang ditunjuk pemilik produk (lihat bagian 8.6) |
| Model biaya | Gratis penuh, memakai paket gratis layanan pihak ketiga |
| Wilayah | Indonesia |
| Login | OTP kode 6 digit dikirim ke email melalui Resend |
| Enkripsi chat | End-to-end wajib sejak MVP, memakai library kriptografi yang sudah teruji (lihat bagian 6) |
| Data lokasi | Hanya titik lokasi terakhir. Tidak ada riwayat perjalanan |
| Batas usia pantau lokasi | Minimal 18 tahun untuk membagikan lokasi langsung |
| Peta publik | Badge lokasi dengan status singkat yang berlaku 8 jam |
| Komentar status | Hanya dari kontak yang sudah saling terhubung, tidak dari publik |

## 6. Teknologi

| Komponen | Teknologi | Peran |
|----------|-----------|-------|
| Aplikasi klien | Flutter (Dart) | Aplikasi Android dan iOS |
| Basis data dan penyimpanan | Supabase (PostgreSQL, Storage, Realtime, Edge Functions) | Profil, kontak, metadata pesan, status publik, komentar, lokasi terakhir, penyimpanan media terenkripsi, logika OTP di server |
| Push notification | Firebase Cloud Messaging | Notifikasi push ke perangkat |
| Login (OTP) | Resend (email OTP), diverifikasi oleh Supabase Edge Function | Pengiriman dan verifikasi kode OTP lewat email |
| Peta dan lokasi | Google Maps Platform (dikonfigurasi di Google Cloud Console) | Peta, geocoding, penentuan posisi |
| Email transaksional | Resend (SMTP dan API) | OTP, pemberitahuan keamanan akun, dan penghapusan akun |
| Enkripsi | Library yang sudah teruji, misalnya libsodium (sodium_libs di Flutter) atau implementasi Signal Protocol bila tersedia untuk Dart | Enkripsi end-to-end untuk pesan, foto, dan voice note privat |

**Catatan pembagian peran:**
- Supabase menjadi sumber data utama dan tempat logika OTP berjalan di Edge Function.
- Firebase dipakai untuk push notification. Login tidak memakai Firebase Authentication.
- Sesi pengguna dikelola oleh Supabase Auth. Pengiriman OTP ke email dilakukan lewat Resend dari Edge Function.
- Kode OTP disimpan dalam bentuk hash, dengan masa berlaku singkat (misalnya 10 menit) dan batas percobaan.
- Penggunaan library kriptografi tidak boleh diubah sendiri. Algoritma tidak boleh diimplementasikan ulang tanpa tinjauan ahli.

## 7. Ruang Lingkup

### 7.1 Dalam Lingkup (MVP)
- Registrasi dan login dengan email dan OTP.
- Manajemen kontak dan permintaan pertemanan.
- Chat satu-ke-satu terenkripsi end-to-end: teks, foto, voice note, status terkirim, terbaca, dan sedang mengetik.
- Permintaan pantau lokasi dua arah dengan persetujuan (khusus pengguna 18 tahun ke atas).
- Peta lokasi pribadi dan kontak yang dipantau.
- Peta publik dengan badge lokasi yang disamarkan.
- Status publik berlaku 8 jam: teks singkat, catatan, dan foto yang dibuka dengan mengetuk badge.
- Komentar pada status publik oleh kontak yang sudah saling terhubung.
- Pengaturan privasi, pemblokiran, dan laporan.

### 7.2 Di Luar Lingkup (Versi Berikutnya)
- Chat grup.
- Panggilan suara dan video.
- Riwayat perjalanan lengkap.
- Fitur kencan atau pencocokan otomatis.
- Integrasi dengan layanan pihak ketiga.
- Verifikasi usia berbasis dokumen.
- Dukungan wilayah selain Indonesia.
- Versi web.

## 8. Persyaratan Fungsional

### 8.1 Autentikasi dan Profil
- **FR-01:** Pengguna mendaftar dengan alamat email. Sistem mengirim kode OTP 6 digit melalui Resend, dan pengguna memasukkannya untuk masuk.
- **FR-02:** Kode OTP berlaku 10 menit, hanya bisa dipakai sekali, dan dibatasi jumlah percobaannya (misalnya 5 kali) dengan jeda sebelum mencoba lagi.
- **FR-03:** Pengguna mengatur nama tampilan, foto profil, dan username unik.
- **FR-04:** Saat pendaftaran, pengguna mengisi tanggal lahir. Fitur pantau lokasi langsung hanya terbuka bagi pengguna yang berusia 18 tahun ke atas. Sistem menyimpan hasil pengecekan ini di profil. Pada tahap ini belum ada verifikasi dokumen. (Lihat pertanyaan terbuka.)
- **FR-05:** Pengguna dapat menghapus akun beserta datanya. Penghapusan diproses di server dan data pribadi dihapus dalam batas waktu yang diumumkan di kebijakan privasi.

### 8.2 Kontak
- **FR-06:** Pengguna menambah kontak melalui email, username, atau kode undangan sekali pakai.
- **FR-07:** Penerima dapat menerima atau menolak permintaan kontak.
- **FR-08:** Pengguna dapat menghapus atau memblokir kontak. Pemblokiran menghentikan chat, pantau lokasi, komentar, dan kemunculan status publik antara kedua pihak.

### 8.3 Chat Terenkripsi End-to-End
- **FR-09:** Setiap perangkat memiliki pasangan kunci. Kunci privat tidak pernah meninggalkan perangkat.
- **FR-10:** Pesan, foto, dan voice note dienkripsi di perangkat pengirim dan didekripsi hanya di perangkat penerima.
- **FR-11:** Server hanya menyimpan ciphertext dan metadata minimal yang diperlukan untuk pengiriman (misalnya ID pengirim, ID penerima, waktu, ukuran).
- **FR-12:** Pengguna dapat memverifikasi kode keamanan kontak untuk memastikan tidak ada pihak ketiga yang menyisipkan diri.
- **FR-13:** Kirim dan terima pesan teks.
- **FR-14:** Kirim foto dari galeri atau kamera, dengan batas ukuran 10 MB per foto dan kompresi otomatis sebelum dienkripsi.
- **FR-15:** Rekam dan kirim voice note dengan batas durasi 5 menit. Pengguna dapat mendengarkan ulang sebelum mengirim.
- **FR-16:** Tampilkan status pesan: terkirim, diterima, dan terbaca.
- **FR-17:** Tampilkan indikator sedang mengetik.
- **FR-18:** Pengguna dapat menghapus pesan untuk diri sendiri atau untuk semua pihak dalam batas waktu 15 menit.
- **FR-19:** Pengguna dapat mencadangkan dan memulihkan riwayat chat dengan kata sandi cadangan yang dikelola pengguna. Server tidak dapat membaca cadangan tersebut.

### 8.4 Pantau Lokasi Pribadi (18 Tahun ke Atas)
- **FR-20:** Hanya pengguna yang berusia 18 tahun ke atas yang dapat mengirim maupun menerima permintaan pantau lokasi langsung.
- **FR-21:** Pengguna dapat mengirim permintaan pantau lokasi ke kontak, satu arah atau dua arah. Kedua pihak harus memenuhi syarat usia.
- **FR-22:** Lokasi tidak dibagikan sebelum penerima menyetujui permintaan.
- **FR-23:** Saat berbagi, pengguna memilih durasi: 1 jam, 8 jam, atau sampai dimatikan manual.
- **FR-24:** Pengguna dapat menghentikan berbagi lokasi kapan saja, dan pihak lain menerima notifikasi.
- **FR-25:** Saat lokasi sedang dibagikan, ikon indikator tampil di seluruh aplikasi dan di bilah status perangkat.
- **FR-26:** Peta pantau menampilkan posisi diri sendiri dan kontak yang membagikan lokasi, dengan waktu pembaruan terakhir.
- **FR-27:** Setiap pihak dapat melihat daftar siapa saja yang sedang memantaunya dan dapat mencabut akses tersebut.
- **FR-28:** Lokasi pribadi yang tersimpan hanya posisi terakhir. Data dihapus setelah sesi berbagi berakhir.

### 8.5 Peta Publik: Badge Lokasi dan Status
- **FR-29:** Pengguna dapat memilih tampil di peta publik. Pengaturan ini nonaktif secara default.
- **FR-30:** Lokasi publik ditampilkan sebagai badge dengan pembulatan atau acakan radius minimal 300 meter. Koordinat presisi tidak pernah dikirim ke klien lain.
- **FR-31:** Pengguna dapat memasang status publik yang terdiri dari teks singkat (maksimal 140 karakter), catatan opsional (maksimal 1.000 karakter), dan foto opsional.
- **FR-32:** Setiap status publik berlaku **8 jam** sejak dipasang. Setelah itu status disembunyikan otomatis dari peta dan dari pengguna lain.
- **FR-33:** Pengguna dapat mengganti atau menghapus status publik kapan saja sebelum masa 8 jam berakhir. Penggantian status memulai ulang masa 8 jam.
- **FR-34:** Status publik terhubung dengan badge lokasi. Pengguna lain dapat melihat status dengan mengetuk badge tersebut.
- **FR-35:** Status publik dapat dikomentari hanya oleh pengguna yang sudah saling terhubung sebagai kontak dengan pemilik status. Pengguna lain tidak dapat berkomentar, dan komentar tidak tampil untuk publik.
- **FR-36:** Pemilik status dapat menghapus komentar pada statusnya. Pengguna dapat menghapus komentarnya sendiri.
- **FR-37:** Pengguna dapat melihat badge lokasi dalam radius tertentu (misalnya 1 km, 5 km, 10 km).
- **FR-38:** Pengguna publik tidak dapat melihat detail pribadi (nama lengkap, email) kecuali ada koneksi kontak dan persetujuan. Badge hanya menampilkan username atau nama samaran dan status.
- **FR-39:** Pengguna dapat mematikan tampil publik kapan saja, dan badge, status, serta komentar langsung hilang dari peta.
- **FR-40:** Foto pada status publik diperiksa dengan pemindaian otomatis dasar (misalnya hash gambar yang sudah dikenal bermasalah) dan dapat dilaporkan oleh pengguna lain.

### 8.6 Keamanan dan Moderasi
- **FR-41:** Pengguna dapat melaporkan profil, status publik, komentar, foto, atau pesan dengan alasan yang dipilih.
- **FR-42:** Laporan atas pesan terenkripsi dikirim bersama salinan pesan yang didekripsi di perangkat pelapor, dengan persetujuan pelapor. Server tidak membaca pesan secara otomatis.
- **FR-43:** Laporan ditandai prioritas tinggi bila menyangkut ancaman, kekerasan, eksploitasi, atau konten yang melibatkan anak. Laporan tersebut diteruskan ke tim penanganan segera.
- **FR-44:** Tim penanganan laporan meninjau laporan dan dapat menghapus konten, menangguhkan akun, atau meneruskan kasus ke pihak berwenang bila diperlukan.
- **FR-45:** Pengguna dapat memblokir pengguna lain dari peta publik dan chat.

### 8.7 Notifikasi
- **FR-46:** Notifikasi push untuk pesan baru, permintaan kontak, permintaan pantau, perubahan status berbagi lokasi, dan komentar pada status.
- **FR-47:** Pengguna dapat mengatur notifikasi per kategori. Isi pesan tidak ditampilkan di notifikasi jika pengguna memilih mode privat.
- **FR-48:** Email transaksional dikirim melalui Resend untuk OTP, pemberitahuan keamanan akun, dan penghapusan akun.

## 9. Struktur Navigasi

Lima tab di bagian bawah layar:

| Tab | Fungsi Utama | Halaman Utama |
|-----|--------------|---------------|
| 1. Chat | Daftar percakapan dan ruang obrolan terenkripsi | Daftar chat, detail chat, verifikasi kode keamanan |
| 2. Pantau | Peta pribadi dan kontak yang dipantau (18+) | Peta, daftar pantau, pengaturan berbagi |
| 3. Sekitar | Peta publik dengan badge lokasi dan status | Peta publik, detail badge (status, catatan, foto, komentar), filter radius, pasang status |
| 4. Kontak | Daftar kontak dan permintaan | Daftar kontak, permintaan masuk, tambah kontak |
| 5. Profil | Akun, privasi, dan pengaturan | Profil, privasi, usia, notifikasi, cadangan chat, bantuan, keluar |

## 10. Alur Pengguna Utama

**Alur A: Daftar dan masuk**
1. Pengguna memasukkan email dan tanggal lahir.
2. Sistem mengirim kode OTP ke email melalui Resend.
3. Pengguna memasukkan kode. Setelah berhasil, pengguna mengatur profil dan kunci enkripsi perangkat dibuat.

**Alur B: Mulai pantau lokasi (18+)**
1. Pengguna membuka tab Kontak, memilih kontak, lalu menekan "Minta pantau". Sistem memastikan kedua pihak berusia 18 tahun ke atas.
2. Pengguna memilih arah (satu atau dua arah) dan durasi.
3. Penerima menerima notifikasi dan menyetujui atau menolak.
4. Setelah disetujui, lokasi tampil di tab Pantau untuk kedua pihak sesuai pengaturan.

**Alur C: Pasang status di peta publik**
1. Pengguna membuka tab Sekitar dan menekan "Tampil di publik" bila belum aktif.
2. Aplikasi menjelaskan bahwa lokasi disamarkan, status berlaku 8 jam, dan tampil publik dapat dimatikan kapan saja. Pengguna mengonfirmasi.
3. Pengguna menekan "Pasang status", mengisi teks singkat, catatan, atau foto.
4. Badge muncul di peta selama 8 jam. Pengguna lain yang mengetuk badge dapat melihat status. Kontak yang terhubung dapat berkomentar.

**Alur D: Komentar status**
1. Kontak yang terhubung mengetuk badge pengguna tersebut.
2. Kontak menulis komentar. Komentar langsung terkirim ke pemilik status dan kontak lain yang terhubung dengan pemilik.
3. Pemilik status dapat menghapus komentar. Pengguna lain tidak melihat komentar tersebut.

**Alur E: Kirim voice note terenkripsi**
1. Pengguna menekan dan menahan tombol mikrofon di chat.
2. Rekaman berjalan dengan indikator durasi. Pengguna dapat membatalkan dengan menggeser.
3. Setelah dilepas, voice note dienkripsi di perangkat lalu dikirim dengan status pengiriman.

**Alur F: Verifikasi kontak**
1. Pengguna membuka info kontak dan memilih "Verifikasi keamanan".
2. Kedua pihak melihat kode yang sama, lalu mencocokkannya secara langsung (misalnya dengan memindai kode QR).
3. Status verifikasi tersimpan di perangkat masing-masing.

## 11. Persyaratan Non-Fungsional

| Kategori | Persyaratan |
|----------|-------------|
| Performa | Pesan terkirim dalam waktu di bawah 2 detik pada koneksi stabil. Peta publik memuat di bawah 3 detik. |
| Pembaruan lokasi | Interval 15 hingga 30 detik saat aplikasi aktif. Interval diperlebar saat baterai rendah atau aplikasi di latar belakang. |
| Keamanan | TLS wajib untuk semua lalu lintas. Enkripsi end-to-end wajib untuk chat privat. Kunci privat disimpan di penyimpanan aman perangkat (Keychain atau Keystore). Kode OTP disimpan dalam bentuk hash. |
| Privasi | Mengikuti UU PDP No. 27 Tahun 2022. Data lokasi dan tanggal lahir diperlakukan sebagai data pribadi yang spesifik. Data minimum dikumpulkan. |
| Ketersediaan | Target uptime 99% per bulan pada tahap gratis, menyesuaikan batasan layanan gratis. |
| Skalabilitas | Mendukung 1.000 pengguna aktif harian pada tahap awal, dengan rencana skala lebih besar setelah tahap berbayar. |
| Aksesibilitas | Mendukung ukuran font sistem, kontras warna yang memadai, dan label untuk pembaca layar. |
| Platform | Android dan iOS. Versi web bukan bagian MVP. |
| Penyimpanan | Foto dan voice note terenkripsi disimpan di Supabase Storage dengan kebijakan retensi yang dapat diatur. Foto status publik dihapus otomatis bersama status setelah 8 jam. |
| Batasan gratis | Pemantauan kuota Supabase, Firebase, Resend (email OTP dan notifikasi), dan Google Maps Platform. Ada rencana penanganan jika kuota mendekati batas. |

## 12. Pertimbangan Privasi dan Keamanan

- Persetujuan eksplisit untuk setiap fitur berbagi lokasi. Tidak ada persetujuan otomatis.
- Pantau lokasi langsung hanya untuk pengguna 18 tahun ke atas, dan syarat ini dicek di server maupun di klien.
- Indikator visual yang jelas saat lokasi dibagikan.
- Tampil publik nonaktif secara default dan dapat dimatikan kapan saja.
- Lokasi publik selalu disamarkan. Koordinat presisi tidak pernah dikirim ke klien lain.
- Status publik otomatis hilang setelah 8 jam. Tidak ada arsip status.
- Riwayat lokasi tidak disimpan jangka panjang.
- Chat privat tidak dapat dibaca server. Moderasi chat hanya bisa lewat laporan dari penerima (FR-42).
- Status publik, komentar, dan foto di peta publik **tidak** dienkripsi end-to-end karena harus dapat dilihat pihak yang berhak. Konten ini dimoderasi dan memiliki masa berlaku.
- Pengguna dapat mengunduh dan menghapus datanya sesuai hak subjek data.
- Kebijakan privasi dan syarat layanan ditampilkan saat pendaftaran dan harus berbahasa Indonesia.

## 13. Metrik Keberhasilan

- **Aktivasi:** persentase pengguna yang menambah minimal satu kontak dalam 24 jam pertama.
- **Retensi:** pengguna aktif mingguan (WAU) pada minggu keempat.
- **Engagement chat:** rata-rata pesan per pengguna aktif per hari.
- **Adopsi pantau lokasi:** persentase pengguna dewasa yang pernah menyelesaikan satu sesi pantau.
- **Adopsi status publik:** persentase pengguna aktif yang memasang minimal satu status per minggu.
- **Keamanan:** jumlah laporan per 1.000 pengguna aktif, persentase laporan prioritas tinggi yang ditangani dalam hari yang sama, dan waktu respons rata-rata.

## 14. Asumsi dan Risiko

| Asumsi / Risiko | Dampak | Mitigasi |
|-----------------|--------|----------|
| Pengguna enggan membagikan lokasi | Adopsi fitur pantau rendah | Onboarding yang menjelaskan manfaat dan kendali privasi |
| Penyalahgunaan peta publik untuk menguntit | Risiko keselamatan tinggi | Penyamaran lokasi, status yang berlaku 8 jam, pemblokiran, moderasi, dan komentar hanya dari kontak terhubung |
| Verifikasi usia hanya mandiri (self-declared) | Pengguna di bawah 18 tahun dapat mengisi tanggal lahir palsu untuk membuka pantau lokasi | Pengecekan usia di server, pemberitahuan kebijakan, laporan, dan rencana verifikasi lanjutan pada versi berikutnya |
| Anak-anak tetap dapat mendaftar dan chat | Risiko keselamatan anak dan sanksi hukum | Pertimbangkan pembatasan fitur foto dan peta publik untuk pengguna yang terindikasi di bawah umur, dan tinjau ketentuan perlindungan anak di sistem elektronik yang berlaku di Indonesia sebelum rilis publik |
| Enkripsi end-to-end membatasi moderasi chat | Konten berbahaya dalam chat sulit dideteksi otomatis | Mekanisme laporan dengan salinan dari perangkat pelapor, serta edukasi pengguna |
| Penanganan laporan darurat bergantung pada satu orang | Respons lambat saat kondisi darurat | Buat SOP tertulis, jadwal piket, dan kontak eskalasi. Sediakan tombol laporan prioritas tinggi |
| Kuota layanan gratis terlampaui (termasuk kuota email Resend untuk OTP) | Login gagal atau layanan terhenti | Pantau pemakaian, batasi pengiriman OTP per email, kompresi media, retensi pendek, dan rencana upgrade bila perlu |
| Konsumsi baterai tinggi | Pengguna mencabut izin lokasi | Interval adaptif dan pembaruan hanya saat sesi berbagi aktif |
| Pengembang tunggal | Kapasitas terbatas dan risiko satu titik kegagalan | Prioritaskan MVP, otomatisasi dasar, cadangan data rutin |
| Kompleksitas E2E dan manajemen kunci | Waktu pengembangan lebih lama, risiko kehilangan riwayat chat | Gunakan library teruji, fitur cadangan kata sandi, dan dokumentasi jelas untuk pengguna |
| Kepatuhan regulasi data pribadi | Sanksi hukum | Konsultasi hukum dan audit privasi sebelum rilis publik |

## 15. Rencana Rilis

- **Fase 0: Riset dan desain.** Wireframe tiap tab, validasi konsep privasi lokasi, penyusunan kebijakan privasi, dan SOP penanganan laporan.
- **Fase 1: Fondasi.** Setup Flutter, Supabase, Firebase (FCM), Google Cloud Console, dan Resend. Login OTP email dan profil dasar.
- **Fase 2: Kontak dan chat teks terenkripsi.** Pertukaran kunci, verifikasi kontak, dan pengiriman pesan teks.
- **Fase 3: Foto, voice note, dan pantau lokasi.** Media terenkripsi dan permintaan pantau dua arah dengan pengecekan usia 18 tahun.
- **Fase 4: Peta publik dan status.** Badge lokasi, status 8 jam, komentar kontak terhubung, dan pemindaian foto dasar.
- **Fase 5: Moderasi dan uji tertutup.** Laporan prioritas tinggi, pemblokiran, notifikasi, dan uji dengan kelompok kecil.
- **Fase 6: Rilis publik Indonesia.** Setelah tinjauan privasi, tinjauan perlindungan anak, dan uji beban dasar selesai.
- **Fase 7: Pengembangan lanjutan.** Chat grup, cadangan lanjutan, panggilan suara, dan verifikasi usia yang lebih kuat.

## 16. Pertanyaan Terbuka

1. Apakah peta publik (badge lokasi) juga memerlukan syarat 18 tahun, atau hanya pantau lokasi langsung? Badge menampilkan area lokasi pengguna, sehingga dapat dianggap sebagai berbagi lokasi. Rekomendasi: berlakukan syarat 18 tahun untuk peta publik juga.
2. Bagaimana pengguna di bawah 18 tahun tetap diperlakukan di aplikasi: apakah peta publik dan pengiriman foto dibatasi untuk mereka?
3. Bagaimana SOP penanganan laporan prioritas tinggi, termasuk target waktu respons, siapa yang dihubungi, dan kapan kasus diteruskan ke pihak berwenang?
4. Pada dokumen awal disebut "tim kami", sedangkan pengembangan dilakukan satu orang. Siapa anggota tim penanganan laporan, dan bagaimana pembagian tugas jika pemilik produk tidak tersedia?
5. Apakah pengguna boleh membalas komentar, atau komentar hanya satu arah ke pemilik status?
6. Bagaimana kebijakan tanggal lahir jika pengguna tidak ingin mengisinya? Apakah pengguna tersebut tetap bisa menggunakan chat dan kontak?
