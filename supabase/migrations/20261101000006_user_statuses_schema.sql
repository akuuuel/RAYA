-- Migrasi: user_statuses (Fitur Status WhatsApp-style antar Kontak)
-- Tabel ini BERBEDA dari public_statuses (yang dipakai fitur Explore/Peta Publik)
-- user_statuses: status 24 jam yang hanya bisa dilihat oleh kontak terhubung

-- ============================================================
-- TABEL user_statuses
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_statuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    caption TEXT NOT NULL DEFAULT '',
    media_data TEXT,           -- base64 image jika ada
    media_url TEXT,            -- URL Supabase Storage (untuk masa depan)
    bg_color BIGINT NOT NULL DEFAULT 4285554407, -- default: 0xFF6C5CE7 (ungu)
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '24 hours'),
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- Indeks performa
CREATE INDEX IF NOT EXISTS idx_user_statuses_user_id
    ON public.user_statuses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_statuses_active
    ON public.user_statuses(is_active, expires_at);
CREATE INDEX IF NOT EXISTS idx_user_statuses_created_at
    ON public.user_statuses(created_at DESC);

-- Aktifkan RLS
ALTER TABLE public.user_statuses ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- KEBIJAKAN RLS
-- ============================================================

-- 1. Pengguna dapat melihat status MILIKNYA SENDIRI
CREATE POLICY "Pengguna dapat melihat status miliknya"
    ON public.user_statuses
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- 2. KONTAK TERHUBUNG dapat melihat status aktif yang belum kedaluwarsa
--    (relasi 2 arah: user_id harus ada di tabel contacts milik pembaca)
CREATE POLICY "Kontak dapat membaca status aktif"
    ON public.user_statuses
    FOR SELECT
    TO authenticated
    USING (
        is_active = true
        AND expires_at > now()
        AND EXISTS (
            SELECT 1 FROM public.contacts
            WHERE contacts.user_id = auth.uid()
              AND contacts.contact_user_id = public.user_statuses.user_id
              AND contacts.is_blocked = false
        )
    );

-- 3. Pengguna hanya bisa INSERT status sebagai dirinya sendiri
CREATE POLICY "Pengguna dapat memposting status miliknya"
    ON public.user_statuses
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- 4. Pengguna hanya bisa UPDATE / DELETE status miliknya
CREATE POLICY "Pengguna dapat mengubah status miliknya"
    ON public.user_statuses
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Pengguna dapat menghapus status miliknya"
    ON public.user_statuses
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================
-- FUNGSI: Bersihkan status kedaluwarsa otomatis (opsional, dijalankan via cron)
-- ============================================================
CREATE OR REPLACE FUNCTION public.cleanup_expired_user_statuses()
RETURNS void AS $$
BEGIN
    UPDATE public.user_statuses
    SET is_active = false
    WHERE is_active = true AND expires_at < now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

