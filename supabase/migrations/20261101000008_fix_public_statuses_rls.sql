-- Migrasi: Perbaikan RLS public_statuses & public_profiles_settings
-- Memastikan pemilik catatan dapat memposting, membaca, dan menghapus catatannya sendiri 100% tanpa hambatan,
-- serta memastikan catatan aktif dapat dibaca dan dikomentari oleh pengguna sekitar di peta.

-- 1. Pemilik catatan memiliki akses penuh (SELECT, INSERT, UPDATE, DELETE) pada catatannya sendiri
DROP POLICY IF EXISTS "Pengguna dapat mengelola status miliknya sendiri" ON public.public_statuses;
DROP POLICY IF EXISTS "Pengguna dapat memasang status publik miliknya" ON public.public_statuses;
DROP POLICY IF EXISTS "Pengguna dapat mengubah atau menonaktifkan status miliknya" ON public.public_statuses;
DROP POLICY IF EXISTS "Pengguna dapat menghapus status miliknya" ON public.public_statuses;

CREATE POLICY "Pengguna dapat mengelola status miliknya sendiri"
    ON public.public_statuses
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 2. Seluruh pengguna terotentikasi dapat membaca catatan publik yang aktif
DROP POLICY IF EXISTS "Status publik aktif dapat dibaca oleh seluruh pengguna terotentikasi" ON public.public_statuses;
CREATE POLICY "Status publik aktif dapat dibaca oleh seluruh pengguna terotentikasi"
    ON public.public_statuses
    FOR SELECT
    TO authenticated
    USING (
        is_active = true AND
        expires_at > now()
    );

-- 3. Pengaturan visibilitas publik dapat dibaca oleh seluruh pengguna terotentikasi
DROP POLICY IF EXISTS "Pengguna dapat membaca pengaturan visibilitas publik" ON public.public_profiles_settings;
CREATE POLICY "Pengguna dapat membaca pengaturan visibilitas publik"
    ON public.public_profiles_settings
    FOR SELECT
    TO authenticated
    USING (true);

