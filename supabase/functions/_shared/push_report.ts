// Shared helpers for all push senders:
//  * allDeviceTokens – pages through device_tokens (one request = max 1000 rows)
//  * forEachBatch   – sends in parallel batches (time limit of edge functions)
//  * beginPushReport / endPushReport – push statistics for the Telegram bot
//    (telegram-push-bot posts and updates a message per push for every
//    subscriber; taps are counted via log_push_open from the app).
// deno-lint-ignore-file no-explicit-any

const BOT_TOKEN = Deno.env.get("TELEGRAM_PUSH_BOT_TOKEN") ?? "";

export async function allDeviceTokens(
  supabase: any,
  filter: "content" | "verse" | "all" = "content",
  columns = "fcm_token, language",
): Promise<any[]> {
  const rows: any[] = [];
  for (let from = 0; ; from += 1000) {
    let q = supabase.from("device_tokens").select(columns).not("fcm_token", "is", null);
    if (filter === "content") q = q.eq("content_notifications", true);
    if (filter === "verse") q = q.eq("verse_notifications", true);
    const { data, error } = await q.order("id").range(from, from + 999);
    if (error) throw error;
    rows.push(...(data ?? []));
    if (!data || data.length < 1000) break;
  }
  const seen = new Set<string>();
  return rows.filter((r) => r.fcm_token && !seen.has(r.fcm_token) && seen.add(r.fcm_token));
}

export async function forEachBatch<T>(items: T[], size: number, fn: (item: T) => Promise<void>) {
  for (let i = 0; i < items.length; i += size) {
    await Promise.all(items.slice(i, i + size).map((it) => fn(it).catch((e) => console.error(e))));
  }
}

export interface PushReport { id: string | null }

/** Creates (or, with a key, reuses) the report row. Never throws. */
export async function beginPushReport(
  supabase: any,
  opts: { category: string; title: string; key?: string },
): Promise<PushReport> {
  try {
    if (opts.key) {
      const { data: existing } = await supabase.from("push_reports").select("id").eq("report_key", opts.key).maybeSingle();
      if (existing) return { id: existing.id };
    }
    const { data, error } = await supabase.from("push_reports")
      .insert({ category: opts.category, title: opts.title, report_key: opts.key ?? null })
      .select("id").single();
    if (error) {
      // created concurrently by another run
      if (opts.key) {
        const { data: again } = await supabase.from("push_reports").select("id").eq("report_key", opts.key).maybeSingle();
        return { id: again?.id ?? null };
      }
      throw error;
    }
    return { id: data.id };
  } catch (e) {
    console.error("[push-report] begin failed", e);
    return { id: null };
  }
}

/** Adds the counts and posts/updates the Telegram message. Never throws. */
export async function endPushReport(supabase: any, report: PushReport, sent: number, failed: number) {
  if (!report.id) return;
  try {
    await supabase.rpc("add_push_report_counts", { p_id: report.id, p_sent: sent, p_failed: failed });
    await syncTelegram(supabase, report.id);
  } catch (e) {
    console.error("[push-report] end failed", e);
  }
}

function fmt(n: number) {
  return n.toLocaleString("de-DE");
}

function esc(s: string) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

export function reportText(r: any): string {
  const when = new Intl.DateTimeFormat("de-DE", {
    timeZone: "Europe/Berlin", day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit",
  }).format(new Date(r.created_at));
  const rate = r.sent > 0 ? ` (${((r.opens / r.sent) * 100).toLocaleString("de-DE", { maximumFractionDigits: 1 })} %)` : "";
  return [
    `📣 <b>${esc(r.category)}</b>`,
    r.title ? `„${esc(String(r.title).slice(0, 200))}“` : "",
    "",
    `📬 Empfangen: <b>${fmt(r.sent)}</b>${r.failed ? `  ·  ⚠️ fehlgeschlagen: ${fmt(r.failed)}` : ""}`,
    `👆 Geöffnet: <b>${fmt(r.opens)}</b>${rate}`,
    "",
    `🕐 ${when} Uhr`,
  ].filter((l, i, a) => !(l === "" && a[i - 1] === "")).join("\n");
}

async function tg(method: string, body: unknown) {
  const res = await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/${method}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  return await res.json().catch(() => ({ ok: false }));
}

/** Posts the report to new subscribers and edits existing messages if the text changed. */
export async function syncTelegram(supabase: any, pushId: string) {
  if (!BOT_TOKEN) return;
  const { data: r } = await supabase.from("push_reports").select("*").eq("id", pushId).maybeSingle();
  if (!r) return;
  const text = reportText(r);
  const { data: subs } = await supabase.from("telegram_subscribers").select("chat_id");
  const { data: msgs } = await supabase.from("telegram_push_messages").select("*").eq("push_id", pushId);
  const byChat = new Map((msgs ?? []).map((m: any) => [String(m.chat_id), m]));
  for (const s of subs ?? []) {
    const m: any = byChat.get(String(s.chat_id));
    if (!m) {
      const res = await tg("sendMessage", { chat_id: s.chat_id, text, parse_mode: "HTML", disable_notification: false });
      if (res.ok) {
        await supabase.from("telegram_push_messages").insert({
          push_id: pushId, chat_id: s.chat_id, message_id: res.result.message_id, last_text: text,
        });
      } else if (res.error_code === 403) {
        await supabase.from("telegram_subscribers").delete().eq("chat_id", s.chat_id); // bot blocked
      }
    } else if (m.last_text !== text) {
      const res = await tg("editMessageText", { chat_id: s.chat_id, message_id: m.message_id, text, parse_mode: "HTML" });
      if (res.ok || String(res.description ?? "").includes("not modified")) {
        await supabase.from("telegram_push_messages").update({ last_text: text })
          .eq("push_id", pushId).eq("chat_id", s.chat_id);
      }
    }
  }
}
