-- Migrasi Supabase: moderation_reports_schema (FR-41 s.d. FR-47)
-- Sistem Pelaporan Konten, Penanganan Prioritas Tinggi, dan Pengaturan Notifikasi

-- 1. Tabel laporan pelanggaran (FR-41 s.d. FR-44)
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    report_type TEXT NOT NULL CHECK (report_type IN ('profile', 'message', 'public_status', 'comment')),
    target_id TEXT NOT NULL,
    reason TEXT NOT NULL,
    is_high_priority BOOLEAN NOT NULL DEFAULT false, -- FR-43: ancaman, kekerasan, eksploitasi, perlindungan anak
    decrypted_content_evidence TEXT, -- FR-42: salinan pesan yang didekripsi di perangkat pelapor atas persetujuan pelapor
    status TEXT NOT NULL CHECK (status IN ('submitted', 'under_review', 'resolved', 'dismissed')) DEFAULT 'submitted',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ,
    CONSTRAINT reporter_not_reported CHECK (reporter_id <> reported_user_id)
);

-- 2. Tabel preferensi notifikasi per pengguna (FR-46, FR-47)
CREATE TABLE IF NOT EXISTS public.notification_settings (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    chat_messages BOOLEAN NOT NULL DEFAULT true,
    contact_requests BOOLEAN NOT NULL DEFAULT true,
    location_tracking BOOLEAN NOT NULL DEFAULT true,
    status_comments BOOLEAN NOT NULL DEFAULT true,
    private_mode BOOLEAN NOT NULL DEFAULT false, -- FR-47: sembunyikan isi pesan di bilah notifikasi perangkat
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indeks performa
CREATE INDEX IF NOT EXISTS idx_reports_high_priority ON public.reports(is_high_priority, status);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON public.reports(reporter_id);

-- Aktifkan Row Level Security (RLS)
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

-- RLS: reports
CREATE POLICY "Pengguna hanya dapat melihat riwayat laporan yang mereka kirim"
    ON public.reports
    FOR SELECT
    TO authenticated
    USING (auth.uid() = reporter_id);

CREATE POLICY "Pengguna terotentikasi dapat mengirimkan laporan"
    ON public.reports
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = reporter_id);

-- RLS: notification_settings
CREATE POLICY "Pengguna dapat mengelola preferensi notifikasi miliknya"
    ON public.notification_settings
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

