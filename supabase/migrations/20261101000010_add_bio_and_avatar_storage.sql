-- Migrasi: Penambahan Kolom Bio & Bucket Avatar untuk Fitur Pengaturan Profil
-- Jalankan di Supabase SQL Editor jika belum tersedia

-- 1. Tambah kolom bio pada tabel profiles jika belum ada
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT;

-- 2. Pastikan Storage Bucket 'avatars' aktif & publik
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 3. Policy Storage untuk mengunggah avatar foto profil sendiri
DROP POLICY IF EXISTS "Pengguna dapat mengunggah avatar miliknya" ON storage.objects;
DROP POLICY IF EXISTS "Semua orang dapat melihat avatar publik" ON storage.objects;

CREATE POLICY "Semua orang dapat melihat avatar publik"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'avatars');

CREATE POLICY "Pengguna dapat mengunggah avatar miliknya"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'avatars' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Pengguna dapat memperbarui avatar miliknya"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'avatars' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

