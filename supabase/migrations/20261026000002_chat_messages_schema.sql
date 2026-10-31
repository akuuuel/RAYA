-- Migrasi Supabase: chat_messages_schema (FR-09, FR-10, FR-11, FR-12, FR-13, FR-16, FR-17, FR-18)
-- Tabel untuk manajemen kunci publik perangkat, percakapan 1-on-1, dan pesan terenkripsi end-to-end

-- 1. Tabel user_keys (Kunci publik perangkat pengguna untuk E2EE)
CREATE TABLE IF NOT EXISTS public.user_keys (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    public_key TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Tabel conversations (Ruang percakapan 1-on-1)
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant_a UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    participant_b UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_conversation_participants UNIQUE (participant_a, participant_b),
    CONSTRAINT participants_different CHECK (participant_a <> participant_b)
);

-- 3. Tabel messages (Pesan terenkripsi end-to-end, server hanya menyimpan ciphertext dan metadata minimal)
CREATE TABLE IF NOT EXISTS public.messages (
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

-- Indeks performa query chat
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_conversations_participants ON public.conversations(participant_a, participant_b);

-- Aktifkan Row Level Security (RLS)
ALTER TABLE public.user_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Kebijakan RLS untuk user_keys
CREATE POLICY "Kunci publik dapat dibaca oleh seluruh pengguna terotentikasi"
    ON public.user_keys
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Pengguna hanya dapat menyimpan dan memperbarui kunci publik miliknya"
    ON public.user_keys
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Kebijakan RLS untuk conversations
CREATE POLICY "Pengguna hanya dapat melihat percakapan miliknya"
    ON public.conversations
    FOR SELECT
    TO authenticated
    USING (auth.uid() = participant_a OR auth.uid() = participant_b);

CREATE POLICY "Pengguna dapat membuat percakapan jika menjadi salah satu pihak"
    ON public.conversations
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = participant_a OR auth.uid() = participant_b);

CREATE POLICY "Peserta dapat memperbarui waktu pesan terakhir percakapan"
    ON public.conversations
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = participant_a OR auth.uid() = participant_b);

-- Kebijakan RLS untuk messages
CREATE POLICY "Pengguna hanya dapat membaca pesan di mana mereka adalah pengirim atau penerima"
    ON public.messages
    FOR SELECT
    TO authenticated
    USING (
        (auth.uid() = sender_id AND NOT deleted_by_sender) OR
        (auth.uid() = recipient_id AND NOT deleted_by_recipient)
    );

CREATE POLICY "Pengguna hanya dapat mengirim pesan sebagai dirinya sendiri"
    ON public.messages
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Pengirim dapat menghapus pesan dan penerima dapat memperbarui status pesan"
    ON public.messages
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

-- Fungsi trigger: memperbarui last_message_at di conversations saat pesan baru masuk
CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversations
    SET last_message_at = NEW.created_at
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER tr_update_conversation_last_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.update_conversation_last_message();

