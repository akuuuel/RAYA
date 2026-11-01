-- Migrasi: Pembaruan RLS status_comments untuk Catatan Sekitar (Nearby Notes)
-- Memungkinkan catatan di peta dikomentari oleh seluruh pengguna sekitar (bukan hanya kontak),
-- dan mencegah pemilik catatan mengomentari catatannya sendiri.

-- 1. Hapus policy lama yang membatasi hanya untuk kontak
DROP POLICY IF EXISTS "Hanya kontak terhubung dan pemilik status yang dapat membaca komentar" ON public.status_comments;
DROP POLICY IF EXISTS "Hanya kontak terhubung yang dapat mengirim komentar pada status" ON public.status_comments;
DROP POLICY IF EXISTS "Seluruh pengguna terotentikasi dapat membaca komentar status" ON public.status_comments;
DROP POLICY IF EXISTS "Pengguna dapat mengomentari catatan orang lain" ON public.status_comments;

-- 2. Kebijakan SELECT: Seluruh pengguna terotentikasi dapat membaca komentar pada catatan sekitar
CREATE POLICY "Seluruh pengguna terotentikasi dapat membaca komentar status"
    ON public.status_comments
    FOR SELECT
    TO authenticated
    USING (true);

-- 3. Kebijakan INSERT: Pengguna dapat mengirim komentar pada catatan milik orang lain (tidak bisa komen catatan sendiri)
CREATE POLICY "Pengguna dapat mengomentari catatan orang lain"
    ON public.status_comments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = author_id AND
        EXISTS (
            SELECT 1 FROM public.public_statuses ps
            WHERE ps.id = status_id
              AND ps.user_id <> auth.uid() -- Tidak bisa komen catatan sendiri
        )
    );

-- 4. Kebijakan DELETE: Penulis komentar atau pemilik catatan dapat menghapus komentar
DROP POLICY IF EXISTS "Penulis komentar atau pemilik status dapat menghapus komentar" ON public.status_comments;
CREATE POLICY "Penulis komentar atau pemilik status dapat menghapus komentar"
    ON public.status_comments
    FOR DELETE
    TO authenticated
    USING (
        auth.uid() = author_id OR
        EXISTS (
            SELECT 1 FROM public.public_statuses ps
            WHERE ps.id = status_comments.status_id AND ps.user_id = auth.uid()
        )
    );

