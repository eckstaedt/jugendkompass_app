import { useInfiniteQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { format } from 'date-fns';
import { supabase } from '@/integrations/supabase/client';
import { DailyVerse } from '@/lib/supabase';
import { logActivity } from '@/lib/activity-logger';
import { usePreviewLocale } from '@/contexts/PreviewLocaleContext';

const PAGE_SIZE = 20;

/**
 * upcoming: from `fromDate` (default today) forward, oldest first – the
 *           automatic planning reaches 10 years ahead, so this is the list
 *           editors work with.
 * past:     before today, newest first.
 */
export type VerseListMode = 'upcoming' | 'past';

const today = () => format(new Date(), 'yyyy-MM-dd');

export const useDailyVerses = (mode: VerseListMode = 'upcoming', fromDate?: string) => {
  const { previewLang } = usePreviewLocale();
  const start = fromDate || today();
  const {
    data,
    isLoading,
    error,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteQuery({
    queryKey: ['dailyVerses', previewLang, mode, start],
    queryFn: async ({ pageParam = 0 }) => {
      const from = pageParam * PAGE_SIZE;
      const to = from + PAGE_SIZE - 1;

      if (previewLang !== 'de') {
        const { data: localized, error: rpcError } = await supabase
          .rpc('get_verse_of_day_localized', { lang: previewLang });
        if (rpcError) throw rpcError;
        const all = [...(localized ?? [])] as any[];
        const filtered = mode === 'upcoming'
          ? all.filter((v) => (v.date ?? '') >= start).sort((a, b) => (a.date ?? '').localeCompare(b.date ?? ''))
          : all.filter((v) => (v.date ?? '') < today()).sort((a, b) => (b.date ?? '').localeCompare(a.date ?? ''));
        const slice = filtered.slice(from, to + 1);
        const ids = slice.map((v: any) => v.id).filter(Boolean);
        let extraMap: Record<string, any> = {};
        if (ids.length) {
          const { data: extra } = await supabase
            .from('verse_of_the_day')
            .select('id, image_url, image_source_hash, auto_scheduled, usage_count, content!verse_of_the_day_content_id_fkey (id, content_type, status, created_at)')
            .in('id', ids);
          extraMap = Object.fromEntries((extra ?? []).map((e: any) => [e.id, e]));
        }
        return slice.map((v: any) => ({ ...(extraMap[v.id] ?? {}), ...v })) as unknown as DailyVerse[];
      }

      let query = supabase
        .from('verse_of_the_day')
        .select(`
          id,
          verse,
          reference,
          date,
          content_id,
          usage_count,
          image_url,
          image_source_hash,
          auto_scheduled,
          content!verse_of_the_day_content_id_fkey (
            id,
            content_type,
            status,
            created_at
          )
        `);

      query = mode === 'upcoming'
        ? query.gte('date', start).order('date', { ascending: true })
        : query.lt('date', today()).order('date', { ascending: false });

      const { data: dailyVerses, error } = await query.range(from, to);

      if (error) {
        console.error('Supabase error:', error);
        throw new Error(error.message);
      }

      return dailyVerses as unknown as DailyVerse[];
    },
    initialPageParam: 0,
    getNextPageParam: (lastPage, allPages) => {
      return lastPage.length === PAGE_SIZE ? allPages.length : undefined;
    },
  });

  const verses = data?.pages.flat() ?? [];

  const queryClient = useQueryClient();
  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['dailyVerses'] });
    queryClient.invalidateQueries({ queryKey: ['verseScheduleOverview'] });
  };

  const createVerse = useMutation({
    mutationFn: async ({ verse, reference, date, image_url, userId }: { verse: string; reference: string; date: string; image_url?: string | null; userId: string }) => {
      const { data: existing } = await supabase
        .from('verse_of_the_day')
        .select('id')
        .eq('date', date)
        .maybeSingle();
      if (existing) {
        throw new Error('Für diesen Tag ist bereits ein Vers geplant – bitte diesen Eintrag bearbeiten.');
      }

      const { data: contentData, error: contentError } = await supabase
        .from('content')
        .insert({ content_type: 'daily_verse', status: 'published' })
        .select('id')
        .single();

      if (contentError) throw contentError;

      const { data: result, error } = await supabase
        .from('verse_of_the_day')
        .insert({ verse, reference, date, image_url: image_url || null, content_id: contentData.id })
        .select('*')
        .single();

      if (error) {
        console.error('Supabase error:', error);
        throw new Error(error.message);
      }

      await logActivity(
        userId,
        'daily_verse',
        'create',
        result.id,
        `Daily verse for ${date} created`
      );

      return result;
    },
    onSuccess: invalidate,
  });

  const updateVerse = useMutation({
    mutationFn: async ({ id, verse, reference, date, image_url, image_source_hash }: { id: string; content_id: string; verse: string; reference: string; date: string; image_url?: string | null; image_source_hash?: string | null }) => {
      const patch: { verse: string; reference: string; date: string; image_url: string | null; image_source_hash?: string | null } =
        { verse, reference, date, image_url: image_url || null };
      // undefined = leave as is; null = image is now a manual upload (never overwritten)
      if (image_source_hash !== undefined) patch.image_source_hash = image_source_hash;
      const { data, error } = await supabase
        .from('verse_of_the_day')
        .update(patch)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: invalidate,
  });

  return {
    verses,
    isLoading,
    error,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    createVerse,
    updateVerse,
  };
};
