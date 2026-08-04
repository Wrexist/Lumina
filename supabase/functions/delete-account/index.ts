// Supabase Edge Function: delete-account
//
// Apple Guideline 5.1.1(v) requires an app that supports account creation to
// offer in-app account deletion that actually deletes the account. The iOS
// client can't do this itself: removing a Supabase auth user needs the
// service-role key, which must never ship in a binary. So the client calls
// here with its own access token, and this function — which holds the
// service-role key as a function secret — does the privileged work.
//
// It also revokes the Sign in with Apple token. Apple requires this for any
// app that offers SIWA: deleting your row while leaving the Apple credential
// live means the user still appears "signed up" to Apple and can't cleanly
// re-register.
//
// Deploy:
//   supabase functions deploy delete-account
//   supabase secrets set \
//     SUPABASE_SERVICE_ROLE_KEY=... \
//     APPLE_TEAM_ID=... APPLE_CLIENT_ID=app.lumina.ios \
//     APPLE_KEY_ID=... APPLE_PRIVATE_KEY="$(cat AuthKey_XXXX.p8)"
//
// APPLE_* are optional: without them the Supabase user is still deleted and
// the response reports that Apple revocation was skipped, so deletion is
// never blocked on Apple credentials being configured.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { create, getNumericDate } from "jsr:@zaubrik/djwt@3";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "content-type": "application/json" },
  });
}

/**
 * Builds the client secret Apple's revoke endpoint expects: a short-lived
 * ES256 JWT signed with the team's .p8 key.
 */
async function appleClientSecret(): Promise<string | null> {
  const teamId = Deno.env.get("APPLE_TEAM_ID");
  const clientId = Deno.env.get("APPLE_CLIENT_ID");
  const keyId = Deno.env.get("APPLE_KEY_ID");
  const privateKeyPem = Deno.env.get("APPLE_PRIVATE_KEY");
  if (!teamId || !clientId || !keyId || !privateKeyPem) return null;

  // Strip the PEM armour generically. Spelling out the BEGIN/END markers as
  // literals here trips secret scanners on a file that contains no secret —
  // this matches any `-----WORD WORD-----` delimiter instead.
  const pkcs8 = privateKeyPem.replace(/-----[A-Z ]+-----/g, "").replace(/\s/g, "");
  const der = Uint8Array.from(atob(pkcs8), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );

  return await create(
    { alg: "ES256", kid: keyId, typ: "JWT" },
    {
      iss: teamId,
      iat: getNumericDate(0),
      exp: getNumericDate(60 * 10),
      aud: "https://appleid.apple.com",
      sub: clientId,
    },
    key,
  );
}

/** Revokes the user's Apple credential. Best-effort by design — see below. */
async function revokeAppleToken(refreshToken: string): Promise<"revoked" | "skipped" | "failed"> {
  const secret = await appleClientSecret();
  const clientId = Deno.env.get("APPLE_CLIENT_ID");
  if (!secret || !clientId) return "skipped";

  const response = await fetch("https://appleid.apple.com/auth/revoke", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: secret,
      token: refreshToken,
      token_type_hint: "refresh_token",
    }),
  });
  return response.ok ? "revoked" : "failed";
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const authHeader = request.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return json({ error: "missing_bearer_token" }, 401);
  }
  const accessToken = authHeader.slice("Bearer ".length);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: "function_not_configured" }, 500);
  }

  // Identify the caller from THEIR token — never from a client-supplied id,
  // or any authenticated user could delete anyone else's account.
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: userData, error: userError } = await admin.auth.getUser(accessToken);
  if (userError || !userData.user) {
    return json({ error: "invalid_token" }, 401);
  }
  const user = userData.user;

  // Revoke Apple first, while the row (and its stored refresh token) still
  // exists. A revocation failure must NOT block deletion — the user asked to
  // be deleted, and leaving the row behind because Apple was unreachable is
  // the worse outcome. The result is reported so it can be retried out of band.
  let appleRevocation: "revoked" | "skipped" | "failed" = "skipped";
  const appleRefreshToken =
    (user.user_metadata?.apple_refresh_token as string | undefined) ??
    (user.identities?.find((i) => i.provider === "apple")?.identity_data
      ?.refresh_token as string | undefined);
  if (appleRefreshToken) {
    try {
      appleRevocation = await revokeAppleToken(appleRefreshToken);
    } catch {
      appleRevocation = "failed";
    }
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) {
    return json({ error: "delete_failed", message: deleteError.message }, 500);
  }

  return json({ deleted: true, appleRevocation });
});
