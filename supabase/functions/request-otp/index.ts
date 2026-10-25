/// <reference path="../global.d.ts" />
// Supabase Edge Function: request-otp (FR-01, FR-02, FR-48)
// Menangani pembuatan kode OTP 6 digit, hashing, rate-limiting, dan pengiriman via Resend.
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
    const { email } = await req.json();

    if (!email || typeof email !== "string") {
      return new Response(
        JSON.stringify({ success: false, message: "Alamat email wajib diisi." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const sanitizedEmail = email.trim().toLowerCase();
    if (!emailRegex.test(sanitizedEmail)) {
      return new Response(
        JSON.stringify({ success: false, message: "Format alamat email tidak valid." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const otpSalt = Deno.env.get("OTP_SALT") ?? "raya-secure-otp-salt-2026";

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Cek Rate Limiting (Maksimal 1 pengiriman per 60 detik)
    const sixtySecondsAgo = new Date(Date.now() - 60 * 1000).toISOString();
    const { data: recentOtps } = await supabase
      .from("email_otps")
      .select("id, created_at")
      .eq("email", sanitizedEmail)
      .gt("created_at", sixtySecondsAgo)
      .limit(1);

    if (recentOtps && recentOtps.length > 0) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Silakan tunggu 60 detik sebelum meminta kode baru.",
        }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Buat kode OTP 6 digit acak kriptografis
    const randomBytes = new Uint32Array(1);
    crypto.getRandomValues(randomBytes);
    const code = (100000 + (randomBytes[0] % 900000)).toString();

    // Hash kode sebelum disimpan ke database (FR-02)
    const otpHash = await sha256Hash(code, otpSalt);
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString(); // Berlaku 10 menit

    // Simpan ke tabel email_otps
    const { error: insertError } = await supabase.from("email_otps").insert({
      email: sanitizedEmail,
      otp_hash: otpHash,
      attempts: 0,
      max_attempts: 5,
      expires_at: expiresAt,
    });

    if (insertError) {
      throw insertError;
    }

    // Kirim email via Resend jika RESEND_API_KEY terkonfigurasi (FR-48)
    if (resendApiKey) {
      const emailRes = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${resendApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: "RAYA <noreply@raya.id>",
          to: [sanitizedEmail],
          subject: `Kode Verifikasi RAYA: ${code}`,
          html: `
            <div style="font-family: sans-serif; background: #07050F; color: #FFFFFF; padding: 32px; border-radius: 16px;">
              <h2 style="color: #A78BFA; margin-bottom: 8px;">RAYA</h2>
              <p style="color: #B8B3C9; margin-bottom: 24px;">Kode verifikasi Anda berlaku selama 10 menit. Jangan bagikan kode ini kepada siapa pun.</p>
              <div style="background: #15121F; border: 1px solid #7C3AED; border-radius: 12px; padding: 20px; text-align: center; font-size: 32px; letter-spacing: 8px; font-weight: bold; color: #FFFFFF;">
                ${code}
              </div>
              <p style="color: #7D7790; font-size: 12px; margin-top: 24px;">Jika Anda tidak merasa meminta kode ini, abaikan email ini.</p>
            </div>
          `,
        }),
      });

      if (!emailRes.ok) {
        const errorText = await emailRes.text();
        console.error("Gagal mengirim email via Resend:", errorText);
      }
    }

    // Response sukses tanpa membocorkan kode ke klien
    return new Response(
      JSON.stringify({
        success: true,
        message: "Kode OTP 6 digit telah dikirim ke alamat email Anda.",
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
