import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

/**
 * Erlaubt nur Service-Role (Cron/Trigger) oder eingeloggte Admins.
 * Gibt bei Erfolg null zurück, sonst eine fertige Fehler-Response.
 */
export async function requireAdminOrServiceRole(
  req: Request,
  corsHeaders: Record<string, string>,
): Promise<Response | null> {
  const json = (body: unknown, status: number) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  const bearer = (req.headers.get("Authorization") ?? "")
    .replace(/^Bearer\s+/i, "")
    .trim();

  if (!bearer) return json({ error: "Unauthorized" }, 401);
  if (bearer === SERVICE_KEY) return null;

  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${bearer}` } },
  });
  const { data: userData } = await userClient.auth.getUser();
  const userId = userData?.user?.id;
  if (!userId) return json({ error: "Unauthorized" }, 401);

  const admin = createClient(SUPABASE_URL, SERVICE_KEY, {
    auth: { persistSession: false },
  });
  const { data: isAdmin } = await admin.rpc("is_admin", { user_id: userId });
  if (!isAdmin) return json({ error: "Forbidden" }, 403);

  return null;
}
