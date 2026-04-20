import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

export type TranslationStatus = 'auto' | 'reviewed' | 'outdated';

export type TranslationRow = {
  id: string;
  content_id: string;
  language: string;
  field_name: string;
  value: string;
  source_hash: string | null;
  status: TranslationStatus;
  updated_at: string;
};

export const SUPPORTED_LANGS = ['en'] as const;
export type SupportedLang = typeof SUPPORTED_LANGS[number];

/**
 * Lädt alle Übersetzungen für eine Liste von content_ids in einer einzigen Query.
 * Liefert eine Map: content_id → language → field_name → row.
 */
export function useTranslationsForContents(contentIds: (string | null | undefined)[]) {
  const ids = Array.from(new Set(contentIds.filter((x): x is string => !!x)));
  return useQuery({
    queryKey: ['content-translations', ids.sort().join(',')],
    enabled: ids.length > 0,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('content_translations')
        .select('*')
        .in('content_id', ids);
      if (error) throw error;
      const map: Record<string, Record<string, Record<string, TranslationRow>>> = {};
      for (const row of (data ?? []) as TranslationRow[]) {
        map[row.content_id] ??= {};
        map[row.content_id][row.language] ??= {};
        map[row.content_id][row.language][row.field_name] = row;
      }
      return map;
    },
    staleTime: 30_000,
  });
}

/**
 * Fasst die Übersetzungs-Status pro Sprache für einen Inhalt zusammen.
 * - 'missing'  : keine Übersetzung vorhanden
 * - 'ok'       : alle erwarteten Felder vorhanden, kein outdated
 * - 'outdated' : mind. eine Übersetzung markiert outdated
 * - 'partial'  : einige erwartete Felder fehlen
 */
export type LangSummaryStatus = 'missing' | 'ok' | 'outdated' | 'partial';

export function summarizeLang(
  byLang: Record<string, Record<string, TranslationRow>> | undefined,
  lang: string,
  expectedFields: string[],
): LangSummaryStatus {
  const fields = byLang?.[lang];
  if (!fields || Object.keys(fields).length === 0) return 'missing';
  const present = expectedFields.filter((f) => !!fields[f]);
  if (present.length === 0) return 'missing';
  const anyOutdated = present.some((f) => fields[f].status === 'outdated');
  if (anyOutdated) return 'outdated';
  if (present.length < expectedFields.length) return 'partial';
  return 'ok';
}

/** Triggert die Edge-Function translate-content. */
export function useRetranslateContent() {
  const { toast } = useToast();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (params: {
      content_id: string;
      target_languages?: string[];
      force?: boolean;
    }) => {
      const { data, error } = await supabase.functions.invoke('translate-content', {
        body: {
          content_id: params.content_id,
          target_languages: params.target_languages ?? [...SUPPORTED_LANGS],
          force: params.force ?? true,
        },
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['content-translations'] });
      toast({
        title: 'Übersetzung aktualisiert',
        description: 'Die Inhalte wurden neu übersetzt.',
      });
    },
    onError: (err: any) => {
      toast({
        title: 'Übersetzung fehlgeschlagen',
        description: err?.message ?? 'Unbekannter Fehler',
        variant: 'destructive',
      });
    },
  });
}
