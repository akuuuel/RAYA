-- Migrasi Supabase: public_statuses_schema (FR-29 s.d. FR-40)
-- Peta Publik: Badge Lokasi Disamarkan (min 300m), Status Berlaku 8 Jam, dan Komentar Kontak Terhubung

-- 1. Tabel pengaturan visibilitas publik pengguna (FR-29)
CREATE TABLE IF NOT EXISTS public.public_profiles_settings (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_public_visible BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Tabel status publik (berlaku 8 jam, FR-31, FR-32, FR-33)
CREATE TABLE IF NOT EXISTS public.public_statuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    text VARCHAR(140) NOT NULL,
    note VARCHAR(1000),
    image_url TEXT,
    fuzzed_latitude DOUBLE PRECISION NOT NULL, -- Koordinat telah disamarkan minimal 300 meter (FR-30)
    fuzzed_longitude DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '8 hours'),
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- 3. Tabel komentar status (hanya untuk kontak yang sudah saling terhubung, FR-35, FR-36)
CREATE TABLE IF NOT EXISTS public.status_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    status_id UUID NOT NULL REFERENCES public.public_statuses(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indeks pencarian status aktif dan radius
CREATE INDEX IF NOT EXISTS idx_public_statuses_active ON public.public_statuses(is_active, expires_at);
CREATE INDEX IF NOT EXISTS idx_public_statuses_user ON public.public_statuses(user_id);
CREATE INDEX IF NOT EXISTS idx_status_comments_status ON public.status_comments(status_id);

-- Aktifkan Row Level Security (RLS)
ALTER TABLE public.public_profiles_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.public_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.status_comments ENABLE ROW LEVEL SECURITY;

-- RLS: public_profiles_settings
CREATE POLICY "Pengguna dapat mengelola pengaturan visibilitas publik miliknya"
    ON public.public_profiles_settings
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- RLS: public_statuses
-- Pengguna lain hanya dapat membaca status jika:
-- 1. Status aktif dan belum kedaluwarsa (< 8 jam, FR-32)
-- 2. Pemilik status mengaktifkan tampil publik (is_public_visible = true, FR-29)
CREATE POLICY "Status publik aktif dapat dibaca oleh seluruh pengguna terotentikasi"
    ON public.public_statuses
    FOR SELECT
    TO authenticated
    USING (
        is_active = true AND
        expires_at > now() AND
        EXISTS (
            SELECT 1 FROM public.public_profiles_settings
            WHERE user_id = public_statuses.user_id AND is_public_visible = true
        )
    );

CREATE POLICY "Pengguna dapat memasang status publik miliknya"
    ON public.public_statuses
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Pengguna dapat mengubah atau menonaktifkan status miliknya"
    ON public.public_statuses
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Pengguna dapat menghapus status miliknya"
    ON public.public_statuses
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- RLS: status_comments (FR-35: hanya kontak yang terhubung dengan pemilik status yang dapat melihat dan memberi komentar)
CREATE POLICY "Hanya kontak terhubung dan pemilik status yang dapat membaca komentar"
    ON public.status_comments
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = author_id OR
        EXISTS (
            SELECT 1 FROM public.public_statuses ps
            JOIN public.contacts c ON c.user_id = ps.user_id
            WHERE ps.id = status_comments.status_id
              AND (ps.user_id = auth.uid() OR c.contact_user_id = auth.uid())
        )
    );

CREATE POLICY "Hanya kontak terhubung yang dapat mengirim komentar pada status"
    ON public.status_comments
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = author_id AND
        EXISTS (
            SELECT 1 FROM public.public_statuses ps
            JOIN public.contacts c ON c.user_id = ps.user_id
            WHERE ps.id = status_id
              AND (ps.user_id = auth.uid() OR c.contact_user_id = auth.uid())
        )
    );

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

