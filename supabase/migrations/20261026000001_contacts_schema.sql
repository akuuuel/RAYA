-- Migrasi Supabase: contacts_schema (FR-06, FR-07, FR-08)
-- Tabel untuk manajemen kontak, permintaan pertemanan, dan pemblokiran

-- 1. Tabel contact_requests (Permintaan kontak)
CREATE TABLE IF NOT EXISTS public.contact_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')) DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_pending_request UNIQUE (sender_id, receiver_id),
    CONSTRAINT sender_not_receiver CHECK (sender_id <> receiver_id)
);

-- 2. Tabel contacts (Daftar kontak dua arah)
CREATE TABLE IF NOT EXISTS public.contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    contact_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    alias TEXT,
    is_blocked BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_user_contact UNIQUE (user_id, contact_user_id),
    CONSTRAINT user_not_contact CHECK (user_id <> contact_user_id)
);

-- Indeks untuk mempercepat pencarian kontak dan relasi
CREATE INDEX IF NOT EXISTS idx_contact_requests_sender ON public.contact_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_contact_requests_receiver ON public.contact_requests(receiver_id);
CREATE INDEX IF NOT EXISTS idx_contacts_user ON public.contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_contacts_contact_user ON public.contacts(contact_user_id);

-- Aktifkan Row Level Security (RLS)
ALTER TABLE public.contact_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;

-- Kebijakan RLS untuk contact_requests
CREATE POLICY "Pengguna dapat melihat permintaan yang dikirim atau diterima"
    ON public.contact_requests
    FOR SELECT
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Pengguna dapat mengirim permintaan kontak baru"
    ON public.contact_requests
    FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Penerima atau pengirim dapat memperbarui status permintaan"
    ON public.contact_requests
    FOR UPDATE
    USING (auth.uid() = receiver_id OR auth.uid() = sender_id);

-- Kebijakan RLS untuk contacts
CREATE POLICY "Pengguna hanya dapat melihat dan mengelola kontak miliknya"
    ON public.contacts
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Fungsi otomatis: saat permintaan kontak diterima (accepted), buat kontak dua arah
CREATE OR REPLACE FUNCTION public.handle_accepted_contact_request()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        -- Masukkan relasi sisi pengirim
        INSERT INTO public.contacts (user_id, contact_user_id)
        VALUES (NEW.sender_id, NEW.receiver_id)
        ON CONFLICT (user_id, contact_user_id) DO NOTHING;

        -- Masukkan relasi sisi penerima
        INSERT INTO public.contacts (user_id, contact_user_id)
        VALUES (NEW.receiver_id, NEW.sender_id)
        ON CONFLICT (user_id, contact_user_id) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER tr_on_contact_request_accepted
    AFTER UPDATE ON public.contact_requests
    FOR EACH ROW
    WHEN (NEW.status = 'accepted' AND OLD.status = 'pending')
    EXECUTE FUNCTION public.handle_accepted_contact_request();

