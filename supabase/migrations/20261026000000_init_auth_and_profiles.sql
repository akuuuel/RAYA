-- Migrasi Awal: Autentikasi, Profil, Penentuan Usia Server-Side, dan Email OTP
-- Sesuai PRD v0.3 (FR-01 s.d. FR-05) dan Batasan Keamanan Bagian 3

-- 1. Fungsi Server untuk Menghitung Apakah Pengguna Berusia 18 Tahun ke Atas (FR-04)
-- Dihitung di sisi server PostgreSQL agar tidak dapat dimanipulasi oleh klien.
CREATE OR REPLACE FUNCTION public.calculate_is_adult(birth_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    IF birth_date IS NULL THEN
        RETURN FALSE;
    END IF;
    -- Memeriksa selisih tahun penuh (18 tahun) dari tanggal lahir hingga hari ini
    RETURN birth_date <= (CURRENT_DATE - INTERVAL '18 years')::DATE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 2. Tabel Profil Pengguna (FR-03, FR-04, FR-05)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    username TEXT UNIQUE,
    display_name TEXT,
    avatar_url TEXT,
    birth_date DATE NOT NULL,
    is_adult BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),

    -- Validasi format username (huruf kecil, angka, underscore, 3-30 karakter)
    CONSTRAINT valid_username CHECK (username IS NULL OR username ~ '^[a-z0-9_]{3,30}$')
);

-- Index untuk pencarian username dan email
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- Trigger untuk Memastikan is_adult Selalu Dihitung oleh Server
CREATE OR REPLACE FUNCTION public.handle_profile_age_check()
RETURNS TRIGGER AS $$
BEGIN
    -- Selalu timpa nilai is_adult berdasarkan fungsi server
    NEW.is_adult := public.calculate_is_adult(NEW.birth_date);
    NEW.updated_at := timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_profile_age_check
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_profile_age_check();

-- 3. Row Level Security (RLS) Wajib untuk Tabel Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Pengguna dapat melihat profil mereka sendiri
CREATE POLICY "Pengguna dapat melihat profil mereka sendiri"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Pengguna dapat melihat profil publik terbatas milik orang lain
CREATE POLICY "Pengguna dapat melihat info publik pengguna lain"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (true);

-- Pengguna hanya dapat memasukkan profil mereka sendiri
CREATE POLICY "Pengguna hanya dapat insert profil milik sendiri"
    ON public.profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Pengguna hanya dapat mengupdate profil mereka sendiri
CREATE POLICY "Pengguna hanya dapat update profil milik sendiri"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Pengguna dapat menghapus profil mereka sendiri
CREATE POLICY "Pengguna dapat delete profil milik sendiri"
    ON public.profiles
    FOR DELETE
    TO authenticated
    USING (auth.uid() = id);

-- 4. Tabel Hash Kode OTP Email (FR-01, FR-02)
-- Catatan Keamanan: Tabel ini TIDAK dapat diakses langsung oleh role 'anon' maupun 'authenticated'.
-- Akses hanya melalui Edge Function dengan role 'service_role'.
CREATE TABLE IF NOT EXISTS public.email_otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    otp_hash TEXT NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 5,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_email_otps_email ON public.email_otps(email);
CREATE INDEX IF NOT EXISTS idx_email_otps_expires ON public.email_otps(expires_at);

-- RLS diaktifkan tanpa kebijakan untuk anon/authenticated (akses ditolak penuh untuk klien)
ALTER TABLE public.email_otps ENABLE ROW LEVEL SECURITY;

-- 5. Fungsi Hapus Akun Pengguna (FR-05)
-- Dipanggil oleh pengguna yang terautentikasi untuk menghapus seluruh data dan auth user.
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS VOID AS $$
DECLARE
    user_id UUID := auth.uid();
BEGIN
    IF user_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: Pengguna tidak terautentikasi';
    END IF;

    -- Hapus profil
    DELETE FROM public.profiles WHERE id = user_id;

    -- Hapus user dari auth.users (akan menghapus sesi aktif)
    DELETE FROM auth.users WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
