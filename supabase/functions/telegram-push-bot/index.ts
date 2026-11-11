// Telegram bot "Push-Statistik".
//  * Telegram webhook: /start subscribes the chat, /stop unsubscribes,
//    /letzte shows the last 5 pushes.
//  * {"action":"refresh"} (cron every 5 min): keeps the messages up to date
//    and, 12 h after a push, posts the open rate as a reply.
// Every push sender calls endPushReport() (../_shared/push_report.ts), which
// posts the message to all subscribers.
// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { reportText, syncTelegram } from "../_shared/push_report.ts";

const BOT_TOKEN = Deno.env.get("TELEGRAM_PUSH_BOT_TOKEN") ?? "";
const WEBHOOK_SECRET = Deno.env.get("TELEGRAM_PUSH_WEBHOOK_SECRET") ?? "";
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

async function reply(chatId: number, text: string) {
  await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ chat_id: chatId, text, parse_mode: "HTML" }),
  });
}

async function handleUpdate(update: any) {
  const msg = update.message ?? update.edited_message;
  if (!msg?.chat?.id || typeof msg.text !== "string") return;
  const chatId = msg.chat.id as number;
  const cmd = msg.text.trim().split(/\s+/)[0].split("@")[0].toLowerCase();
  const name = [msg.from?.first_name, msg.from?.last_name].filter(Boolean).join(" ") || msg.chat.title || "";

  if (cmd === "/start") {
    await supabase.from("telegram_subscribers").upsert({ chat_id: chatId, name });
    await reply(chatId,
      "✅ <b>Angemeldet.</b>\nDu bekommst ab jetzt zu jeder Push-Nachricht der Jugendkompass-App " +
      "eine Nachricht: Kategorie, Titel und wie viele sie bekommen haben. 12 Stunden später " +
      "folgt, wie viele sie geöffnet haben (in %).\n\n/letzte – die letzten 5 Pushes\n/stop – abmelden");
  } else if (cmd === "/stop") {
    await supabase.from("telegram_subscribers").delete().eq("chat_id", chatId);
    await reply(chatId, "👋 Abgemeldet. Mit /start kannst du dich wieder anmelden.");
  } else if (cmd === "/letzte") {
    const { data } = await supabase.from("push_reports").select("*").order("created_at", { ascending: false }).limit(5);
    await reply(chatId, (data ?? []).length ? (data ?? []).map(reportText).join("\n\n──────────\n\n") : "Noch keine Pushes erfasst.");
  } else {
    await reply(chatId, "/letzte – die letzten 5 Pushes\n/stop – abmelden");
  }
}

async function refresh() {
  // Recent pushes, plus older ones whose 12 h result is still outstanding.
  const since = new Date(Date.now() - 3 * 24 * 3600 * 1000).toISOString();
  const { data } = await supabase.from("push_reports").select("id")
    .or(`created_at.gte.${since},opens_reported_at.is.null`).order("created_at").limit(200);
  for (const r of data ?? []) await syncTelegram(supabase, r.id);
  return (data ?? []).length;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("ok");
  const body = await req.json().catch(() => ({}));

  // Telegram webhook (authenticated by the secret token set with setWebhook)
  if (body.update_id !== undefined) {
    if (!WEBHOOK_SECRET || req.headers.get("x-telegram-bot-api-secret-token") !== WEBHOOK_SECRET) {
      return new Response("forbidden", { status: 403 });
    }
    try { await handleUpdate(body); } catch (e) { console.error(e); }
    return new Response("ok");
  }

  // Refresh of the tap counters (harmless: only re-renders existing reports)
  if (body.action === "refresh") {
    const n = await refresh();
    return new Response(JSON.stringify({ refreshed: n }), { headers: { "Content-Type": "application/json" } });
  }
  return new Response("unknown", { status: 400 });
});
