-- =========================================================================
-- RAYA: Master Database Setup Script (Clean Re-install)
-- Menghapus tabel lama dengan skema usang dan membuat ulang skema bersih
-- untuk seluruh modul: profiles, contacts, E2EE chat, live tracking,
--                      peta publik 8 jam, dan laporan moderasi.
-- =========================================================================

-- 0. BERSIHKAN TABEL LAMA DENGAN CASCADE AGAR TIDAK ADA KONFLIK SKEMA
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.notification_settings CASCADE;
DROP TABLE IF EXISTS public.status_comments CASCADE;
DROP TABLE IF EXISTS public.public_statuses CASCADE;
DROP TABLE IF EXISTS public.public_profiles_settings CASCADE;
DROP TABLE IF EXISTS public.user_locations CASCADE;
DROP TABLE IF EXISTS public.location_sessions CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.conversations CASCADE;
DROP TABLE IF EXISTS public.user_keys CASCADE;
DROP TABLE IF EXISTS public.contacts CASCADE;
DROP TABLE IF EXISTS public.contact_requests CASCADE;
DROP TABLE IF EXISTS public.email_otps CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;


-- =========================================================================
-- 1. PROFILES & AUTENTIKASI (FR-01 s/d FR-05)
-- =========================================================================

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    username TEXT UNIQUE,
    display_name TEXT,
    birth_date DATE,
    is_adult BOOLEAN DEFAULT false,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT username_min_length CHECK (username IS NULL OR length(username) >= 3)
);

CREATE INDEX idx_profiles_username ON public.profiles(username);
CREATE INDEX idx_profiles_email ON public.profiles(email);

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

CREATE TRIGGER tr_calculate_is_adult
    BEFORE INSERT OR UPDATE OF birth_date ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_is_adult();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email)
    VALUES (NEW.id, COALESCE(NEW.email, ''))
    ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

CREATE TABLE public.email_otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    otp_hash TEXT NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 5,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_email_otps_lookup ON public.email_otps(email, expires_at, consumed_at);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_otps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Semua pengguna terotentikasi dapat mencari dan melihat profil"
    ON public.profiles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Pengguna dapat menyisipkan profil miliknya sendiri"
    ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "Pengguna hanya dapat memperbarui profil miliknya sendiri"
    ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "Pengguna hanya dapat menghapus profil miliknya sendiri"
    ON public.profiles FOR DELETE TO authenticated USING (auth.uid() = id);

CREATE POLICY "Service role akses penuh email_otps"
    ON public.email_otps FOR ALL TO service_role USING (true) WITH CHECK (true);


-- =========================================================================
-- 2. KONTAK & RELASI DUA ARAH (FR-06, FR-07, FR-08)
-- =========================================================================

CREATE TABLE public.contact_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')) DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_pending_request UNIQUE (sender_id, receiver_id),
    CONSTRAINT sender_not_receiver CHECK (sender_id <> receiver_id)
);

CREATE TABLE public.contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    contact_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    alias TEXT,
    is_blocked BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_user_contact UNIQUE (user_id, contact_user_id),
    CONSTRAINT user_not_contact CHECK (user_id <> contact_user_id)
);

CREATE INDEX idx_contact_requests_sender ON public.contact_requests(sender_id);
CREATE INDEX idx_contact_requests_receiver ON public.contact_requests(receiver_id);
CREATE INDEX idx_contacts_user ON public.contacts(user_id);
CREATE INDEX idx_contacts_contact_user ON public.contacts(contact_user_id);

ALTER TABLE public.contact_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pengguna dapat melihat permintaan yang dikirim atau diterima"
    ON public.contact_requests FOR SELECT TO authenticated
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Pengguna dapat mengirim permintaan kontak baru"
    ON public.contact_requests FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Penerima atau pengirim dapat memperbarui status permintaan"
    ON public.contact_requests FOR UPDATE TO authenticated
    USING (auth.uid() = receiver_id OR auth.uid() = sender_id);

CREATE POLICY "Pengguna hanya dapat melihat dan mengelola kontak miliknya"
    ON public.contacts FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.handle_accepted_contact_request()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        INSERT INTO public.contacts (user_id, contact_user_id)
        VALUES (NEW.sender_id, NEW.receiver_id)
        ON CONFLICT (user_id, contact_user_id) DO NOTHING;

        INSERT INTO public.contacts (user_id, contact_user_id)
        VALUES (NEW.receiver_id, NEW.sender_id)
        ON CONFLICT (user_id, contact_user_id) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER tr_on_contact_request_accepted
    AFTER UPDATE ON public.contact_requests
    FOR EACH ROW
    WHEN (NEW.status = 'accepted' AND OLD.status = 'pending')
    EXECUTE FUNCTION public.handle_accepted_contact_request();


-- =========================================================================
-- 3. CHAT E2EE & SAFETY NUMBER (FR-09 s/d FR-18)
-- =========================================================================

CREATE TABLE public.user_keys (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    public_key TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant_a UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    participant_b UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_conversation_participants UNIQUE (participant_a, participant_b),
    CONSTRAINT participants_different CHECK (participant_a <> participant_b)
);

CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    ciphertext TEXT NOT NULL,
    nonce TEXT NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'voice')),
    status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sending', 'sent', 'delivered', 'read')),
    deleted_for_all BOOLEAN NOT NULL DEFAULT false,
    deleted_by_sender BOOLEAN NOT NULL DEFAULT false,
    deleted_by_recipient BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at);
CREATE INDEX idx_conversations_participants ON public.conversations(participant_a, participant_b);

ALTER TABLE public.user_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kunci publik dapat dibaca oleh seluruh pengguna terotentikasi"
    ON public.user_keys FOR SELECT TO authenticated USING (true);

CREATE POLICY "Pengguna hanya dapat menyimpan dan memperbarui kunci publik miliknya"
    ON public.user_keys FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Pengguna hanya dapat melihat percakapan miliknya"
    ON public.conversations FOR SELECT TO authenticated
    USING (auth.uid() = participant_a OR auth.uid() = participant_b);

CREATE POLICY "Pengguna dapat membuat percakapan jika menjadi salah satu pihak"
    ON public.conversations FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = participant_a OR auth.uid() = participant_b);

CREATE POLICY "Peserta dapat memperbarui waktu pesan terakhir percakapan"
    ON public.conversations FOR UPDATE TO authenticated
    USING (auth.uid() = participant_a OR auth.uid() = participant_b);

CREATE POLICY "Pengguna hanya dapat membaca pesan di mana mereka adalah pengirim atau penerima"
    ON public.messages FOR SELECT TO authenticated
    USING (
        (auth.uid() = sender_id AND NOT deleted_by_sender) OR
        (auth.uid() = recipient_id AND NOT deleted_by_recipient)
    );

CREATE POLICY "Pengguna hanya dapat mengirim pesan sebagai dirinya sendiri"
    ON public.messages FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Pengirim dapat menghapus pesan dan penerima dapat memperbarui status pesan"
    ON public.messages FOR UPDATE TO authenticated
    USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversations
    SET last_message_at = NEW.created_at
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER tr_update_conversation_last_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.update_conversation_last_message();


-- =========================================================================
-- 4. PANTAU LOKASI 2 ARAH (18+) (FR-20 s/d FR-28)
-- =========================================================================

CREATE TABLE public.location_sessions (
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

CREATE TABLE public.user_locations (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_location_sessions_requester ON public.location_sessions(requester_id);
CREATE INDEX idx_location_sessions_target ON public.location_sessions(target_id);
CREATE INDEX idx_location_sessions_status ON public.location_sessions(status);

ALTER TABLE public.location_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pengguna dewasa dapat melihat sesi pantau miliknya"
    ON public.location_sessions FOR SELECT TO authenticated
    USING (auth.uid() = requester_id OR auth.uid() = target_id);

CREATE POLICY "Pengguna dewasa (18+) dapat membuat permintaan pantau lokasi"
    ON public.location_sessions FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = requester_id AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND is_adult = true
        )
    );

CREATE POLICY "Pihak yang terlibat dapat memperbarui status sesi pantau"
    ON public.location_sessions FOR UPDATE TO authenticated
    USING (auth.uid() = requester_id OR auth.uid() = target_id);

CREATE POLICY "Pengguna dapat memperbarui koordinat posisi terakhir miliknya"
    ON public.user_locations FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Kontak hanya dapat membaca lokasi jika ada sesi aktif yang belum kedaluwarsa"
    ON public.user_locations FOR SELECT TO authenticated
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

CREATE OR REPLACE FUNCTION public.clean_location_on_session_stop()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'stopped' AND OLD.status = 'active' THEN
        NEW.stopped_at = now();
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

CREATE TRIGGER tr_clean_location_on_session_stop
    BEFORE UPDATE ON public.location_sessions
    FOR EACH ROW
    WHEN (NEW.status = 'stopped' AND OLD.status = 'active')
    EXECUTE FUNCTION public.clean_location_on_session_stop();


-- =========================================================================
-- 5. PETA PUBLIK & STATUS 8 JAM (FR-29 s/d FR-40)
-- =========================================================================

CREATE TABLE public.public_profiles_settings (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_public_visible BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.public_statuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    text VARCHAR(140) NOT NULL,
    note VARCHAR(1000),
    image_url TEXT,
    fuzzed_latitude DOUBLE PRECISION NOT NULL,
    fuzzed_longitude DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '8 hours'),
    is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE public.status_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    status_id UUID NOT NULL REFERENCES public.public_statuses(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_public_statuses_active ON public.public_statuses(is_active, expires_at);
CREATE INDEX idx_public_statuses_user ON public.public_statuses(user_id);
CREATE INDEX idx_status_comments_status ON public.status_comments(status_id);

ALTER TABLE public.public_profiles_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.public_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.status_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pengguna dapat mengelola pengaturan visibilitas publik miliknya"
    ON public.public_profiles_settings FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Status publik aktif dapat dibaca oleh seluruh pengguna terotentikasi"
    ON public.public_statuses FOR SELECT TO authenticated
    USING (
        is_active = true AND
        expires_at > now() AND
        EXISTS (
            SELECT 1 FROM public.public_profiles_settings
            WHERE user_id = public_statuses.user_id AND is_public_visible = true
        )
    );

CREATE POLICY "Pengguna dapat memasang status publik miliknya"
    ON public.public_statuses FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Pengguna dapat mengubah atau menonaktifkan status miliknya"
    ON public.public_statuses FOR UPDATE TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Pengguna dapat menghapus status miliknya"
    ON public.public_statuses FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Hanya kontak terhubung dan pemilik status yang dapat membaca komentar"
    ON public.status_comments FOR SELECT TO authenticated
    USING (
        auth.uid() = author_id OR
        EXISTS (
            SELECT 1 FROM public.public_statuses ps
            JOIN public.contacts c ON c.user_id = ps.user_id
            WHERE ps.id = status_comments.status_id
              AND (ps.user_id = auth.uid() OR c.contact_user_id = auth.uid())
        )
    );

CREATE POLICY "Hanya kontak terhubung yang dapat memberi komentar"
    ON public.status_comments FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = author_id AND
        EXISTS (
            SELECT 1 FROM public.public_statuses ps
            JOIN public.contacts c ON c.user_id = ps.user_id
            WHERE ps.id = status_comments.status_id
              AND (ps.user_id = auth.uid() OR (c.contact_user_id = auth.uid() AND c.is_blocked = false))
        )
    );

CREATE POLICY "Penulis atau pemilik status dapat menghapus komentar"
    ON public.status_comments FOR DELETE TO authenticated
    USING (
        auth.uid() = author_id OR
        EXISTS (
            SELECT 1 FROM public.public_statuses ps
            WHERE ps.id = status_comments.status_id AND ps.user_id = auth.uid()
        )
    );


-- =========================================================================
-- 6. MODERASI, LAPORAN & NOTIFIKASI (FR-41 s/d FR-48)
-- =========================================================================

CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    report_type TEXT NOT NULL CHECK (report_type IN ('profile', 'message', 'public_status', 'comment')),
    target_id TEXT NOT NULL,
    reason TEXT NOT NULL,
    is_high_priority BOOLEAN NOT NULL DEFAULT false,
    decrypted_content_evidence TEXT,
    status TEXT NOT NULL CHECK (status IN ('submitted', 'under_review', 'resolved', 'dismissed')) DEFAULT 'submitted',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ,
    CONSTRAINT reporter_not_reported CHECK (reporter_id <> reported_user_id)
);

CREATE TABLE public.notification_settings (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    chat_messages BOOLEAN NOT NULL DEFAULT true,
    contact_requests BOOLEAN NOT NULL DEFAULT true,
    location_tracking BOOLEAN NOT NULL DEFAULT true,
    status_comments BOOLEAN NOT NULL DEFAULT true,
    private_mode BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_reports_high_priority ON public.reports(is_high_priority, status);
CREATE INDEX idx_reports_reporter ON public.reports(reporter_id);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pengguna hanya dapat melihat riwayat laporan yang mereka kirim"
    ON public.reports FOR SELECT TO authenticated USING (auth.uid() = reporter_id);

CREATE POLICY "Pengguna terotentikasi dapat mengirimkan laporan"
    ON public.reports FOR INSERT TO authenticated WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Pengguna dapat mengelola preferensi notifikasi miliknya"
    ON public.notification_settings FOR ALL TO authenticated
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- SELESAI
