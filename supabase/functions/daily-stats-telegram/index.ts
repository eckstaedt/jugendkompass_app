// Daily Telegram report: installs + app opens for "today" (Europe/Berlin).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const TELEGRAM_GATEWAY = "https://connector-gateway.lovable.dev/telegram";
const CHAT_IDS = ["63117481", "8027531086"];
const TZ = "Europe/Berlin";

function berlinDayBoundsUtc(): { startUtc: string; endUtc: string; label: string } {
  // Compute today's start (00:00) and end (24:00) in Europe/Berlin, expressed as UTC ISO timestamps.
  const now = new Date();
  const fmt = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });
  const parts = Object.fromEntries(fmt.formatToParts(now).map((p) => [p.type, p.value]));
  const y = parts.year, m = parts.month, d = parts.day;
  // Determine Berlin's UTC offset right now via the difference of formatted vs UTC.
  const asUtc = Date.UTC(+y, +m - 1, +d, +parts.hour, +parts.minute, +parts.second);
  const offsetMs = asUtc - now.getTime();
  // Yesterday's full Berlin day
  const endUtc = new Date(Date.UTC(+y, +m - 1, +d, 0, 0, 0) - offsetMs);
  const startUtc = new Date(endUtc.getTime() - 24 * 60 * 60 * 1000);
  const yLabel = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ, year: "numeric", month: "2-digit", day: "2-digit",
  }).format(startUtc).split("-");
  return {
    startUtc: startUtc.toISOString(),
    endUtc: endUtc.toISOString(),
    label: `${yLabel[2]}.${yLabel[1]}.${yLabel[0]}`,
  };
}

Deno.serve(async (req) => {
  try {
    // Berlin-hour gate: only run at 08:00 local. Allows ?force=1 for manual runs.
    const url = new URL(req.url);
    const force = url.searchParams.get("force") === "1";
    const berlinHour = parseInt(
      new Intl.DateTimeFormat("en-GB", { timeZone: TZ, hour: "2-digit", hour12: false })
        .format(new Date()),
      10,
    );
    if (!force && berlinHour !== 8) {
      return new Response(JSON.stringify({ skipped: true, berlinHour }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const LOVABLE_API_KEY = Deno.env.get("LOVABLE_API_KEY");
    const TELEGRAM_API_KEY = Deno.env.get("TELEGRAM_API_KEY");
    if (!LOVABLE_API_KEY) throw new Error("LOVABLE_API_KEY is not configured");
    if (!TELEGRAM_API_KEY) throw new Error("TELEGRAM_API_KEY is not configured");

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { persistSession: false } },
    );

    const { startUtc, endUtc, label } = berlinDayBoundsUtc();

    const { data: installRows, error: installErr } = await supabase
      .from("app_analytics")
      .select("device_id")
      .eq("event_type", "install")
      .gte("created_at", startUtc)
      .lt("created_at", endUtc);
    if (installErr) throw installErr;

    const { data: openRows, error: openErr } = await supabase
      .from("app_analytics")
      .select("device_id")
      .eq("event_type", "app_open")
      .gte("created_at", startUtc)
      .lt("created_at", endUtc);
    if (openErr) throw openErr;

    const installs = new Set((installRows ?? []).map((r: any) => r.device_id)).size;
    const opens = (openRows ?? []).length;
    const uniqueOpeners = new Set((openRows ?? []).map((r: any) => r.device_id)).size;

    const text =
      `📊 <b>Jugendkompass – Tagesreport für ${label}</b>\n\n` +
      `📥 Neue Installationen: <b>${installs}</b>\n` +
      `📱 App-Öffnungen: <b>${opens}</b>\n` +
      `👥 Aktive Geräte: <b>${uniqueOpeners}</b>`;

    const tgRes = await fetch(`${TELEGRAM_GATEWAY}/sendMessage`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${LOVABLE_API_KEY}`,
        "X-Connection-Api-Key": TELEGRAM_API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ chat_id: CHAT_ID, text, parse_mode: "HTML" }),
    });
    const tgData = await tgRes.json();
    if (!tgRes.ok) {
      throw new Error(`Telegram failed [${tgRes.status}]: ${JSON.stringify(tgData)}`);
    }

    return new Response(
      JSON.stringify({ success: true, installs, opens, uniqueOpeners, label }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("daily-stats-telegram error", e);
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
