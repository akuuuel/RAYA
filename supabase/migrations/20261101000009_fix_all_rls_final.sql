-- ============================================================
-- MIGRASI FINAL: Perbaikan Semua RLS untuk Catatan Sekitar & Status
-- Jalankan script ini di Supabase Dashboard > SQL Editor
-- ============================================================

-- ==========================
-- 1. FIX RLS: public_statuses
-- ==========================

-- Hapus semua policy lama yang mungkin konflik
DROP POLICY IF EXISTS "Pengguna dapat mengelola status miliknya sendiri" ON public.public_statuses;
DROP POLICY IF EXISTS "Pengguna dapat memasang status publik miliknya" ON public.public_statuses;
DROP POLICY IF EXISTS "Pengguna dapat mengubah atau menonaktifkan status miliknya" ON public.public_statuses;
DROP POLICY IF EXISTS "Pengguna dapat menghapus status miliknya" ON public.public_statuses;
DROP POLICY IF EXISTS "Status publik aktif dapat dibaca oleh seluruh pengguna terotentikasi" ON public.public_statuses;
DROP POLICY IF EXISTS "Hanya pemilik yang dapat memasang status" ON public.public_statuses;
DROP POLICY IF EXISTS "Pengguna dapat membaca catatan sekitar yang aktif" ON public.public_statuses;

-- Policy 1: Pemilik punya akses PENUH (SELECT, INSERT, UPDATE, DELETE)
CREATE POLICY "Pemilik catatan memiliki akses penuh"
    ON public.public_statuses
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy 2: Semua authenticated bisa membaca catatan aktif
CREATE POLICY "Semua pengguna dapat membaca catatan aktif"
    ON public.public_statuses
    FOR SELECT
    TO authenticated
    USING (is_active = true AND expires_at > now());

-- ==========================
-- 2. FIX RLS: status_comments
-- ==========================

DROP POLICY IF EXISTS "Hanya kontak terhubung dan pemilik status yang dapat membaca komentar" ON public.status_comments;
DROP POLICY IF EXISTS "Hanya kontak terhubung yang dapat mengirim komentar pada status" ON public.status_comments;
DROP POLICY IF EXISTS "Seluruh pengguna terotentikasi dapat membaca komentar status" ON public.status_comments;
DROP POLICY IF EXISTS "Pengguna dapat mengomentari catatan orang lain" ON public.status_comments;
DROP POLICY IF EXISTS "Pemilik komentar dapat menghapus komentarnya" ON public.status_comments;

-- Semua authenticated bisa baca komentar
CREATE POLICY "Semua pengguna dapat membaca komentar"
    ON public.status_comments
    FOR SELECT
    TO authenticated
    USING (true);

-- Hanya non-pemilik catatan yang bisa insert komentar
CREATE POLICY "Pengguna dapat mengomentari catatan orang lain"
    ON public.status_comments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = author_id AND
        EXISTS (
            SELECT 1 FROM public.public_statuses ps
            WHERE ps.id = status_id AND ps.user_id <> auth.uid()
        )
    );

-- Pemilik komentar bisa hapus komentar miliknya
CREATE POLICY "Pemilik komentar dapat menghapus komentarnya"
    ON public.status_comments
    FOR DELETE
    TO authenticated
    USING (auth.uid() = author_id);

-- ==========================
-- 3. FIX RLS: public_profiles_settings
-- ==========================

DROP POLICY IF EXISTS "Pengguna dapat membaca pengaturan visibilitas publik" ON public.public_profiles_settings;
DROP POLICY IF EXISTS "Pengguna dapat mengelola pengaturan visibilitasnya sendiri" ON public.public_profiles_settings;
DROP POLICY IF EXISTS "Pengguna hanya dapat mengelola setting visibilitas miliknya" ON public.public_profiles_settings;

-- Semua authenticated bisa baca settings (dibutuhkan saat fetch catatan)
CREATE POLICY "Semua pengguna dapat membaca settings visibilitas"
    ON public.public_profiles_settings
    FOR SELECT
    TO authenticated
    USING (true);

-- Setiap pengguna bisa kelola settings miliknya sendiri
CREATE POLICY "Pengguna mengelola settings visibilitas miliknya"
    ON public.public_profiles_settings
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ==========================
-- 4. AKTIFKAN REALTIME (jika belum)
-- Menggunakan DO block agar tidak error jika tabel sudah terdaftar
-- ==========================

DO $$
DECLARE
    tbl TEXT;
    tbls TEXT[] := ARRAY['public_statuses', 'status_comments', 'user_statuses'];
BEGIN
    FOREACH tbl IN ARRAY tbls LOOP
        -- Cek apakah tabel ada
        IF EXISTS (
            SELECT 1 FROM pg_tables
            WHERE schemaname = 'public' AND tablename = tbl
        ) THEN
            -- Cek apakah tabel sudah terdaftar di publikasi
            IF NOT EXISTS (
                SELECT 1 FROM pg_publication_tables
                WHERE pubname = 'supabase_realtime'
                  AND schemaname = 'public'
                  AND tablename = tbl
            ) THEN
                EXECUTE format(
                    'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl
                );
                RAISE NOTICE 'Realtime diaktifkan untuk tabel: %', tbl;
            ELSE
                RAISE NOTICE 'Tabel % sudah terdaftar di supabase_realtime, dilewati.', tbl;
            END IF;
        ELSE
            RAISE NOTICE 'Tabel % tidak ditemukan, dilewati.', tbl;
        END IF;
    END LOOP;
END $$;

