-- Migrasi Supabase: profiles_and_auth_schema (FR-01 s/d FR-05)
-- Skema tabel profil pengguna, batas usia 18+, dan penyimpanan OTP sementara

-- 1. Tabel profiles (Profil Pengguna RAYA)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    username TEXT UNIQUE,
    display_name TEXT,
    birth_date DATE,
    is_adult BOOLEAN DEFAULT false,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT username_min_length CHECK (username IS NULL OR length(username) >= 3)
);

-- Indeks untuk pencarian username dan email
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- Trigger penghitungan status dewasa 18+ otomatis berdasarkan birth_date (FR-04)
CREATE OR REPLACE FUNCTION public.calculate_is_adult()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.birth_date IS NOT NULL THEN
        NEW.is_adult := (NEW.birth_date <= (CURRENT_DATE - INTERVAL '18 years'));
    ELSE
        NEW.is_adult := false;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tr_calculate_is_adult
    BEFORE INSERT OR UPDATE OF birth_date ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_is_adult();

-- Trigger otomatis membuat record profiles saat user mendaftar di auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email)
    VALUES (NEW.id, NEW.email)
    ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 2. Tabel email_otps (Penyimpanan OTP 6 digit ber-hash SHA-256 untuk verifikasi tanpa kata sandi - FR-02)
CREATE TABLE IF NOT EXISTS public.email_otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    otp_hash TEXT NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 5,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_email_otps_lookup ON public.email_otps(email, expires_at, consumed_at);

-- 3. Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_otps ENABLE ROW LEVEL SECURITY;

-- Kebijakan RLS Profiles
CREATE POLICY "Semua pengguna terotentikasi dapat mencari dan melihat profil"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Pengguna hanya dapat memperbarui profil miliknya sendiri"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Pengguna hanya dapat menghapus profil miliknya sendiri"
    ON public.profiles
    FOR DELETE
    TO authenticated
    USING (auth.uid() = id);

-- Kebijakan RLS email_otps (Hanya Service Role yang boleh mengakses)
CREATE POLICY "Service role akses penuh email_otps"
    ON public.email_otps
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

