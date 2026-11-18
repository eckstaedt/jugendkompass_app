import { useInfiniteQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { DailyVerse } from '@/lib/supabase';
import { logActivity } from '@/lib/activity-logger';
import { usePreviewLocale } from '@/contexts/PreviewLocaleContext';

const PAGE_SIZE = 20;

export type VerseFilter = {
  /** Text in Vers oder Bibelstelle (ab 2 Zeichen) */
  search?: string;
  /** yyyy-MM-dd: Liste beginnt bei diesem Datum (und geht zurück in die Vergangenheit) */
  jumpDate?: string;
};

/** Bibelstelle vergleichbar machen: "Römerbrief 8:28" ~ "römer8,28" (wie ref_key in der DB) */
const refKey = (value: string) =>
  value
    .toLowerCase()
    .replace(/brief/g, '')
    .replace(/[\s.]/g, '')
    .replace(/:/g, ',');

/** Wert für PostgREST-or()-Filter sicher in Anführungszeichen setzen */
const quoted = (value: string) => `"${value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;

export const useDailyVerses = (filter: VerseFilter = {}) => {
  const { previewLang } = usePreviewLocale();
  const search = (filter.search ?? '').trim();
  const activeSearch = search.length >= 2 ? search : '';
  const jumpDate = activeSearch ? undefined : filter.jumpDate;
  const {
    data,
    isLoading,
    error,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteQuery({
    queryKey: ['dailyVerses', previewLang, activeSearch, jumpDate ?? ''],
    queryFn: async ({ pageParam = 0 }) => {
      const from = pageParam * PAGE_SIZE;
      const to = from + PAGE_SIZE - 1;

      if (previewLang !== 'de') {
        const { data: localized, error: rpcError } = await supabase
          .rpc('get_verse_of_day_localized', { lang: previewLang });
        if (rpcError) throw rpcError;
        const needle = activeSearch.toLowerCase();
        const sorted = [...(localized ?? [])]
          .filter((v) =>
            (!jumpDate || (v.date ?? '') <= jumpDate) &&
            (!needle ||
              (v.verse ?? '').toLowerCase().includes(needle) ||
              (v.reference ?? '').toLowerCase().includes(needle) ||
              refKey(v.reference ?? '').includes(refKey(needle))))
          .sort((a: any, b: any) => (b.date ?? '').localeCompare(a.date ?? ''));
        const slice = sorted.slice(from, to + 1);
        const contentIds = slice.map((v: any) => v.content_id).filter(Boolean);
        let contentMap: Record<string, any> = {};
        if (contentIds.length) {
          const { data: contents } = await supabase
            .from('content')
            .select('id, content_type, status, created_at')
            .in('id', contentIds);
          contentMap = Object.fromEntries((contents ?? []).map((c: any) => [c.id, c]));
        }
        return slice.map((v: any) => ({ ...v, content: contentMap[v.content_id] })) as unknown as DailyVerse[];
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
          content!verse_of_the_day_content_id_fkey (
            id,
            content_type,
            status,
            created_at
          )
        `);

      if (activeSearch) {
        const like = (v: string) => quoted(`%${v}%`);
        query = query.or(
          [
            `verse.ilike.${like(activeSearch)}`,
            `reference.ilike.${like(activeSearch)}`,
            `ref_key.ilike.${like(refKey(activeSearch))}`,
          ].join(','),
        );
      }
      if (jumpDate) {
        query = query.lte('date', jumpDate);
      }

      const { data: dailyVerses, error } = await query
        .order('date', { ascending: false })
        .range(from, to);

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
  
  const createVerse = useMutation({
    mutationFn: async ({ verse, reference, date, image_url, userId }: { verse: string; reference: string; date: string; image_url?: string | null; userId: string }) => {
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
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dailyVerses'] });
    }
  });

  const updateVerse = useMutation({
    mutationFn: async ({ id, content_id, verse, reference, date, image_url }: { id: string; content_id: string; verse: string; reference: string; date: string; image_url?: string | null }) => {
      const { data, error } = await supabase
        .from('verse_of_the_day')
        .update({ verse, reference, date, image_url: image_url || null })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dailyVerses'] });
    }
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

