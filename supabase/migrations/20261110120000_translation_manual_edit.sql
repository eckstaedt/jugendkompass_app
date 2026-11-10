-- ═══════════════════════════════════════════════════════════════════════════
-- Translation panel: manual translations per record / language / field
--   * tp_content_list        – all translatable records + per-language coverage
--   * tp_record_source       – German source fields of one record
--   * tp_record_editor       – source + translations of one record (editor)
--   * tp_save_translation    – write a manual translation (status = 'manual',
--                              the worker never overwrites those)
--   * tp_reset_translation   – back to automatic: drop manual flag + re-queue
-- All RPCs are SECURITY DEFINER and check public.users.role = 'admin'.
-- ═══════════════════════════════════════════════════════════════════════════

BEGIN;

-- Same hash as process-translation-jobs: sha256("v2:" + trimmed text).
-- Stored on manual rows so the panel can flag them when the German original
-- changes later (the worker itself never touches manual rows).
CREATE OR REPLACE FUNCTION public.tp_source_hash(p_text text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE WHEN p_text IS NULL THEN NULL
    ELSE encode(sha256(convert_to('v2:' || btrim(p_text, E' \t\n\r\f\x0B'), 'UTF8')), 'hex') END;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- Source fields of one record (same field names as process-translation-jobs)
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.tp_record_source(p_content_type text, p_record_id text)
RETURNS TABLE (field_name text, label text, kind text, source_text text, sort integer)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.tp_require_admin();
  CASE p_content_type
    WHEN 'post' THEN
      RETURN QUERY SELECT v.f, v.l, v.k, v.t, v.s FROM public.posts p,
        LATERAL (VALUES ('title', 'Titel', 'text', p.title::text, 1), ('body', 'Text', 'html', p.body::text, 2)) v(f, l, k, t, s)
        WHERE p.id::text = p_record_id;
    WHEN 'message' THEN
      RETURN QUERY SELECT v.f, v.l, v.k, v.t, v.s FROM public.messages m,
        LATERAL (VALUES ('title', 'Titel', 'text', m.title::text, 1), ('message', 'Nachricht', 'long', m.message::text, 2)) v(f, l, k, t, s)
        WHERE m.id::text = p_record_id;
    WHEN 'impulse' THEN
      RETURN QUERY SELECT v.f, v.l, v.k, v.t, v.s FROM public.impulses i,
        LATERAL (VALUES ('title', 'Titel', 'text', i.title::text, 1), ('impulse_text', 'Impuls-Text', 'long', i.impulse_text::text, 2)) v(f, l, k, t, s)
        WHERE i.id::text = p_record_id;
    WHEN 'video' THEN
      RETURN QUERY SELECT v.f, v.l, v.k, v.t, v.s FROM public.videos x,
        LATERAL (VALUES ('title', 'Titel', 'text', x.title::text, 1), ('description', 'Beschreibung', 'long', x.description::text, 2)) v(f, l, k, t, s)
        WHERE x.id::text = p_record_id;
    WHEN 'verse' THEN
      RETURN QUERY SELECT v.f, v.l, v.k, v.t, v.s FROM public.verse_of_the_day d,
        LATERAL (VALUES ('verse', 'Vers', 'long', d.verse::text, 1), ('reference', 'Bibelstelle', 'text', d.reference::text, 2)) v(f, l, k, t, s)
        WHERE d.id::text = p_record_id;
    WHEN 'poll' THEN
      RETURN QUERY
        SELECT 'question'::text, 'Frage'::text, 'text'::text, pl.question::text, 1 FROM public.polls pl WHERE pl.id::text = p_record_id
        UNION ALL
        SELECT 'option:' || o.id::text, 'Antwort ' || (row_number() OVER (ORDER BY o.created_at, o.id))::text,
               'text'::text, o.option_text::text, (10 + row_number() OVER (ORDER BY o.created_at, o.id))::integer
        FROM public.poll_options o WHERE o.poll_id::text = p_record_id;
    WHEN 'edition' THEN
      RETURN QUERY SELECT v.f, v.l, v.k, v.t, v.s FROM public.editions e,
        LATERAL (VALUES ('name', 'Name', 'text', e.name::text, 1), ('title', 'Titel', 'text', e.title::text, 2), ('body', 'Text', 'html', e.body::text, 3)) v(f, l, k, t, s)
        WHERE e.id::text = p_record_id;
    WHEN 'category' THEN
      RETURN QUERY SELECT 'name'::text, 'Name'::text, 'text'::text, c.name::text, 1 FROM public.categories c WHERE c.id::text = p_record_id;
    ELSE
      RAISE EXCEPTION 'unknown content type %', p_content_type;
  END CASE;
END;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- All translatable records with per-language coverage
--   langs = { "en": { "n": <translated fields>, "manual": <manual fields> }, … }
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.tp_content_list(
  p_content_type text DEFAULT NULL,
  p_search text DEFAULT NULL,
  p_limit integer DEFAULT 50,
  p_offset integer DEFAULT 0
)
RETURNS TABLE (
  content_type text, record_id text, title text, created_at timestamptz,
  field_count integer, langs jsonb, total_count bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.tp_require_admin();
  RETURN QUERY
  WITH src AS (
    SELECT 'post'::text AS ty, p.id::text AS rid, p.content_id AS cid, p.title::text AS t, p.created_at::timestamptz AS ts,
           (p.title IS NOT NULL)::int + (p.body IS NOT NULL)::int AS fc
      FROM public.posts p WHERE p_content_type IS NULL OR p_content_type = 'post'
    UNION ALL
    SELECT 'message', m.id::text, m.content_id, m.title::text, m.created_at::timestamptz,
           (m.title IS NOT NULL)::int + (m.message IS NOT NULL)::int
      FROM public.messages m WHERE p_content_type IS NULL OR p_content_type = 'message'
    UNION ALL
    SELECT 'impulse', i.id::text, i.content_id, i.title::text, i.created_at::timestamptz,
           (i.title IS NOT NULL)::int + (i.impulse_text IS NOT NULL)::int
      FROM public.impulses i WHERE p_content_type IS NULL OR p_content_type = 'impulse'
    UNION ALL
    SELECT 'video', v.id::text, v.content_id, v.title::text, v.created_at::timestamptz,
           (v.title IS NOT NULL)::int + (v.description IS NOT NULL)::int
      FROM public.videos v WHERE p_content_type IS NULL OR p_content_type = 'video'
    UNION ALL
    SELECT 'verse', d.id::text, d.content_id, (d.reference || ' (' || d.date::text || ')')::text, d.created_at::timestamptz,
           (d.verse IS NOT NULL)::int + (d.reference IS NOT NULL)::int
      FROM public.verse_of_the_day d WHERE p_content_type IS NULL OR p_content_type = 'verse'
    UNION ALL
    SELECT 'poll', pl.id::text, pl.content_id, pl.question::text, pl.created_at::timestamptz,
           1 + (SELECT count(*)::int FROM public.poll_options o WHERE o.poll_id = pl.id)
      FROM public.polls pl WHERE p_content_type IS NULL OR p_content_type = 'poll'
    UNION ALL
    SELECT 'edition', e.id::text, NULL::uuid, coalesce(e.title, e.name)::text, (to_jsonb(e) ->> 'created_at')::timestamptz,
           (e.name IS NOT NULL)::int + (e.title IS NOT NULL)::int + (e.body IS NOT NULL)::int
      FROM public.editions e WHERE p_content_type IS NULL OR p_content_type = 'edition'
    UNION ALL
    SELECT 'category', c.id::text, NULL::uuid, c.name::text, c.created_at::timestamptz, 1
      FROM public.categories c WHERE p_content_type IS NULL OR p_content_type = 'category'
  ), filtered AS (
    SELECT s.*, count(*) OVER () AS cnt FROM src s
    WHERE p_search IS NULL OR p_search = '' OR s.t ILIKE '%' || p_search || '%' OR s.rid = p_search
    ORDER BY s.ts DESC NULLS LAST, s.rid
    LIMIT LEAST(greatest(p_limit, 1), 500) OFFSET greatest(p_offset, 0)
  )
  SELECT f.ty, f.rid, coalesce(f.t, f.rid), f.ts, f.fc::integer,
    coalesce((
      SELECT jsonb_object_agg(x.language, jsonb_build_object('n', x.n, 'manual', x.manual))
      FROM (
        SELECT tr.language, count(*) AS n, count(*) FILTER (WHERE tr.status = 'manual') AS manual
        FROM (
          SELECT ct.language, ct.status FROM public.content_translations ct
            WHERE f.cid IS NOT NULL AND ct.content_id = f.cid
          UNION ALL
          SELECT et.language, et.status FROM public.entity_translations et
            WHERE f.cid IS NULL AND et.entity_type = f.ty AND et.entity_id = f.rid
        ) tr GROUP BY tr.language
      ) x
    ), '{}'::jsonb),
    f.cnt
  FROM filtered f
  ORDER BY f.ts DESC NULLS LAST, f.rid;
END;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- Everything the editor needs for one record:
--   { "source": [{field_name,label,kind,text,hash}],
--     "translations": [{language,field_name,value,status,source_hash,updated_at}] }
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.tp_record_editor(p_content_type text, p_record_id text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_cid uuid; v_src jsonb; v_tr jsonb;
BEGIN
  PERFORM public.tp_require_admin();
  SELECT coalesce(jsonb_agg(jsonb_build_object(
      'field_name', s.field_name, 'label', s.label, 'kind', s.kind,
      'text', s.source_text, 'hash', public.tp_source_hash(s.source_text)) ORDER BY s.sort), '[]'::jsonb)
    INTO v_src
  FROM public.tp_record_source(p_content_type, p_record_id) s
  WHERE s.source_text IS NOT NULL AND btrim(s.source_text) <> '';

  IF p_content_type IN ('edition', 'category') THEN
    SELECT coalesce(jsonb_agg(jsonb_build_object('language', e.language, 'field_name', e.field_name, 'value', e.value,
        'status', e.status, 'source_hash', e.source_hash, 'updated_at', e.updated_at)), '[]'::jsonb)
      INTO v_tr
    FROM public.entity_translations e WHERE e.entity_type = p_content_type AND e.entity_id = p_record_id;
  ELSE
    SELECT s.content_id INTO v_cid FROM public.tp_content_ids(p_content_type) s WHERE s.record_id = p_record_id;
    SELECT coalesce(jsonb_agg(jsonb_build_object('language', c.language, 'field_name', c.field_name, 'value', c.value,
        'status', c.status, 'source_hash', c.source_hash, 'updated_at', c.updated_at)), '[]'::jsonb)
      INTO v_tr
    FROM public.content_translations c WHERE c.content_id = v_cid;
  END IF;
  RETURN jsonb_build_object('source', v_src, 'translations', v_tr);
END;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- Save a manual translation
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.tp_save_translation(
  p_content_type text, p_record_id text, p_language text, p_field_name text, p_value text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_cid uuid; v_hash text;
BEGIN
  PERFORM public.tp_require_admin();
  IF p_value IS NULL OR btrim(p_value) = '' THEN
    RAISE EXCEPTION 'Übersetzung darf nicht leer sein (zum Entfernen „Automatisch“ verwenden)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.translation_targets WHERE language_code = p_language) THEN
    RAISE EXCEPTION 'unbekannte Sprache %', p_language;
  END IF;
  SELECT public.tp_source_hash(s.source_text) INTO v_hash
  FROM public.tp_record_source(p_content_type, p_record_id) s WHERE s.field_name = p_field_name;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Feld % existiert für %/% nicht', p_field_name, p_content_type, p_record_id;
  END IF;

  IF p_content_type IN ('edition', 'category') THEN
    INSERT INTO public.entity_translations (entity_type, entity_id, language, field_name, value, status, source_hash)
    VALUES (p_content_type, p_record_id, p_language, p_field_name, p_value, 'manual', v_hash)
    ON CONFLICT (entity_type, entity_id, language, field_name)
    DO UPDATE SET value = EXCLUDED.value, status = 'manual', source_hash = EXCLUDED.source_hash, updated_at = now();
  ELSE
    SELECT s.content_id INTO v_cid FROM public.tp_content_ids(p_content_type) s WHERE s.record_id = p_record_id;
    IF v_cid IS NULL THEN
      RAISE EXCEPTION 'Eintrag %/% hat keine content_id', p_content_type, p_record_id;
    END IF;
    INSERT INTO public.content_translations (content_id, language, field_name, value, status, source_hash)
    VALUES (v_cid, p_language, p_field_name, p_value, 'manual', v_hash)
    ON CONFLICT (content_id, language, field_name)
    DO UPDATE SET value = EXCLUDED.value, status = 'manual', source_hash = EXCLUDED.source_hash, updated_at = now();
  END IF;

  PERFORM public.tp_log(format('Manuelle Übersetzung gespeichert: %s/%s [%s] %s',
    p_content_type, p_record_id, p_language, p_field_name), p_content_type);
END;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- Back to automatic (one field, or all fields of a language when
-- p_field_name IS NULL): remove manual flag, force re-translation, re-queue.
-- ───────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.tp_reset_translation(
  p_content_type text, p_record_id text, p_language text, p_field_name text DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_cid uuid; v_n integer;
BEGIN
  PERFORM public.tp_require_admin();
  IF p_content_type IN ('edition', 'category') THEN
    UPDATE public.entity_translations SET status = 'auto', source_hash = NULL, updated_at = now()
    WHERE entity_type = p_content_type AND entity_id = p_record_id AND language = p_language
      AND (p_field_name IS NULL OR field_name = p_field_name);
  ELSE
    SELECT s.content_id INTO v_cid FROM public.tp_content_ids(p_content_type) s WHERE s.record_id = p_record_id;
    UPDATE public.content_translations SET status = 'auto', source_hash = NULL, updated_at = now()
    WHERE content_id = v_cid AND language = p_language
      AND (p_field_name IS NULL OR field_name = p_field_name);
  END IF;
  GET DIAGNOSTICS v_n = ROW_COUNT;

  PERFORM public.enqueue_translation(p_content_type, p_record_id, 20);
  PERFORM public.tp_log(format('Auf automatisch zurückgesetzt: %s/%s [%s] %s',
    p_content_type, p_record_id, p_language, coalesce(p_field_name, 'alle Felder')), p_content_type);
  PERFORM public.kick_translation_worker();
  RETURN v_n;
END;
$$;

REVOKE ALL ON FUNCTION public.tp_record_source(text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.tp_record_editor(text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.tp_content_list(text, text, integer, integer) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.tp_save_translation(text, text, text, text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.tp_reset_translation(text, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.tp_record_source(text, text), public.tp_record_editor(text, text),
  public.tp_content_list(text, text, integer, integer),
  public.tp_save_translation(text, text, text, text, text),
  public.tp_reset_translation(text, text, text, text) TO authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;
