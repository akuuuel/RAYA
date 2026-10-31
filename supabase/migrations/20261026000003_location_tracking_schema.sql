-- Migrasi Supabase: location_tracking_schema (FR-20 s.d. FR-28)
-- Tabel untuk sesi pantau lokasi pribadi dua arah khusus pengguna 18+

-- 1. Tabel location_sessions (Sesi berbagi lokasi pribadi)
CREATE TABLE IF NOT EXISTS public.location_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    target_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_bidirectional BOOLEAN NOT NULL DEFAULT true,
    duration_type TEXT NOT NULL CHECK (duration_type IN ('1_hour', '8_hours', 'manual')),
    expires_at TIMESTAMPTZ,
    status TEXT NOT NULL CHECK (status IN ('pending', 'active', 'stopped', 'rejected')) DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    stopped_at TIMESTAMPTZ,
    CONSTRAINT requester_not_target CHECK (requester_id <> target_id)
);

-- 2. Tabel user_locations (Hanya titik koordinat terakhir, FR-28)
CREATE TABLE IF NOT EXISTS public.user_locations (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indeks performa
CREATE INDEX IF NOT EXISTS idx_location_sessions_requester ON public.location_sessions(requester_id);
CREATE INDEX IF NOT EXISTS idx_location_sessions_target ON public.location_sessions(target_id);
CREATE INDEX IF NOT EXISTS idx_location_sessions_status ON public.location_sessions(status);

-- Aktifkan Row Level Security (RLS)
ALTER TABLE public.location_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;

-- RLS: location_sessions
CREATE POLICY "Pengguna dewasa dapat melihat sesi pantau miliknya"
    ON public.location_sessions
    FOR SELECT
    TO authenticated
    USING (auth.uid() = requester_id OR auth.uid() = target_id);

CREATE POLICY "Pengguna dewasa (18+) dapat membuat permintaan pantau lokasi"
    ON public.location_sessions
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = requester_id AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND is_adult = true
        )
    );

CREATE POLICY "Pihak yang terlibat dapat memperbarui status sesi pantau"
    ON public.location_sessions
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = requester_id OR auth.uid() = target_id);

-- RLS: user_locations
CREATE POLICY "Pengguna dapat memperbarui koordinat posisi terakhir miliknya"
    ON public.user_locations
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Kontak hanya dapat membaca lokasi jika ada sesi aktif yang belum kedaluwarsa"
    ON public.user_locations
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.location_sessions
            WHERE status = 'active'
              AND (expires_at IS NULL OR expires_at > now())
              AND (
                  (requester_id = auth.uid() AND target_id = user_locations.user_id) OR
                  (target_id = auth.uid() AND requester_id = user_locations.user_id AND is_bidirectional = true)
              )
        )
    );

-- Fungsi pembersih otomatis data lokasi setelah sesi berhenti (FR-28)
CREATE OR REPLACE FUNCTION public.clean_location_on_session_stop()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'stopped' AND OLD.status = 'active' THEN
        NEW.stopped_at = now();
        -- Jika tidak ada lagi sesi aktif lain untuk requester atau target, hapus posisi
        DELETE FROM public.user_locations
        WHERE user_id IN (NEW.requester_id, NEW.target_id)
          AND NOT EXISTS (
              SELECT 1 FROM public.location_sessions
              WHERE id <> NEW.id
                AND status = 'active'
                AND (requester_id = user_locations.user_id OR target_id = user_locations.user_id)
          );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER tr_clean_location_on_session_stop
    BEFORE UPDATE ON public.location_sessions
    FOR EACH ROW
    WHEN (NEW.status = 'stopped' AND OLD.status = 'active')
    EXECUTE FUNCTION public.clean_location_on_session_stop();

