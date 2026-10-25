/// <reference path="../global.d.ts" />
// Supabase Edge Function: verify-otp (FR-01, FR-02)
// Menangani validasi kode OTP 6 digit, penghitungan batas percobaan, dan inisiasi sesi pengguna.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function sha256Hash(code: string, salt: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(`${code}:${salt}`);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { email, otp } = await req.json();

    if (!email || !otp) {
      return new Response(
        JSON.stringify({ success: false, message: "Email dan kode OTP wajib diisi." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const sanitizedEmail = email.trim().toLowerCase();
    const sanitizedOtp = otp.trim();

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const otpSalt = Deno.env.get("OTP_SALT") ?? "raya-secure-otp-salt-2026";

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Ambil record OTP aktif terbaru untuk email ini
    const nowIso = new Date().toISOString();
    const { data: records, error: fetchError } = await supabase
      .from("email_otps")
      .select("id, otp_hash, attempts, max_attempts, expires_at, consumed_at")
      .eq("email", sanitizedEmail)
      .is("consumed_at", null)
      .gt("expires_at", nowIso)
      .order("created_at", { ascending: false })
      .limit(1);

    if (fetchError || !records || records.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Kode OTP tidak valid atau sudah kedaluwarsa. Silakan minta kode baru.",
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const otpRecord = records[0];

    // Cek batas percobaan (maksimal 5 kali percobaan sesuai FR-02)
    if (otpRecord.attempts >= otpRecord.max_attempts) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Batas percobaan terlampaui. Silakan minta kode baru.",
          isMaxAttemptsReached: true,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Cocokkan hash OTP
    const inputHash = await sha256Hash(sanitizedOtp, otpSalt);
    if (inputHash !== otpRecord.otp_hash) {
      const newAttempts = otpRecord.attempts + 1;
      await supabase
        .from("email_otps")
        .update({ attempts: newAttempts })
        .eq("id", otpRecord.id);

      const remainingAttempts = Math.max(0, otpRecord.max_attempts - newAttempts);
      const message = remainingAttempts > 0
          ? `Kode salah. Sisa ${remainingAttempts} percobaan.`
          : "Kode salah. Batas percobaan habis. Silakan minta kode baru.";

      return new Response(
        JSON.stringify({
          success: false,
          message: message,
          remainingAttempts: remainingAttempts,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // OTP Valid: Tandai sebagai consumed
    await supabase
      .from("email_otps")
      .update({ consumed_at: nowIso })
      .eq("id", otpRecord.id);

    // Pastikan user ada di Supabase Auth
    let userId: string;
    const { data: existingUsers } = await supabase.auth.admin.listUsers();
    const existingUser = existingUsers?.users?.find(
      (u: { email?: string; id: string }) => u.email?.toLowerCase() === sanitizedEmail
    );

    if (existingUser) {
      userId = existingUser.id;
    } else {
      const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
        email: sanitizedEmail,
        email_confirm: true,
      });
      if (createError || !newUser?.user) {
        throw createError ?? new Error("Gagal membuat akun pengguna.");
      }
      userId = newUser.user.id;
    }

    // Cek apakah profil sudah dilengkapi (nama, username, tanggal lahir)
    const { data: profile } = await supabase
      .from("profiles")
      .select("id, username, is_adult")
      .eq("id", userId)
      .maybeSingle();

    const isNewUser = !profile || !profile.username;

    // Buat session magic link / auth token untuk login klien
    const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
      type: "magiclink",
      email: sanitizedEmail,
    });

    if (linkError) {
      throw linkError;
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Verifikasi berhasil.",
        userId: userId,
        email: sanitizedEmail,
        isNewUser: isNewUser,
        isAdult: profile?.is_adult ?? false,
        hashedToken: linkData?.properties?.hashed_token,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : "Terjadi kesalahan internal";
    return new Response(
      JSON.stringify({ success: false, message: errorMsg }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
