import { useInfiniteQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { DailyVerse } from '@/lib/supabase';
import { logActivity } from '@/lib/activity-logger';
import { usePreviewLocale } from '@/contexts/PreviewLocaleContext';

const PAGE_SIZE = 20;

export const useDailyVerses = () => {
  const { previewLang } = usePreviewLocale();
  const {
    data,
    isLoading,
    error,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteQuery({
    queryKey: ['dailyVerses', previewLang],
    queryFn: async ({ pageParam = 0 }) => {
      const from = pageParam * PAGE_SIZE;
      const to = from + PAGE_SIZE - 1;

      if (previewLang === 'en') {
        const { data: localized, error: rpcError } = await supabase
          .rpc('get_verse_of_day_localized', { lang: 'en' });
        if (rpcError) throw rpcError;
        const sorted = [...(localized ?? [])].sort((a: any, b: any) =>
          (b.date ?? '').localeCompare(a.date ?? '')
        );
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

      const { data: dailyVerses, error } = await supabase
        .from('verse_of_the_day')
        .select(`
          id, 
          verse, 
          reference, 
          date, 
          content_id,
          content!verse_of_the_day_content_id_fkey (
            id,
            content_type,
            status,
            created_at
          )
        `)
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
    mutationFn: async ({ verse, reference, date, userId }: { verse: string; reference: string; date: string; userId: string }) => {
      const { data: contentData, error: contentError } = await supabase
        .from('content')
        .insert({ content_type: 'daily_verse', status: 'published' })
        .select('id')
        .single();

      if (contentError) throw contentError;

      const { data: result, error } = await supabase
        .from('verse_of_the_day')
        .insert({ verse, reference, date, content_id: contentData.id })
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
    mutationFn: async ({ id, content_id, verse, reference, date }: { id: string; content_id: string; verse: string; reference: string; date: string }) => {
      const { data, error } = await supabase
        .from('verse_of_the_day')
        .update({ verse, reference, date })
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

  const bulkCreateVerses = useMutation({
    mutationFn: async ({ verses, userId }: { verses: { verse: string; reference: string; date: string }[]; userId: string }) => {
      // Create content entries for each verse
      const contentInserts = verses.map(() => ({ content_type: 'daily_verse', status: 'published' }));
      const { data: contentData, error: contentError } = await supabase
        .from('content')
        .insert(contentInserts)
        .select('id');

      if (contentError) throw contentError;
      if (!contentData || contentData.length !== verses.length) throw new Error('Content creation mismatch');

      const verseInserts = verses.map((v, i) => ({
        verse: v.verse,
        reference: v.reference,
        date: v.date,
        content_id: contentData[i].id,
      }));

      const { data, error } = await supabase
        .from('verse_of_the_day')
        .insert(verseInserts)
        .select('*');

      if (error) throw error;

      await logActivity(userId, 'daily_verse', 'create', null as any, `${verses.length} Verse per Bulk-Import erstellt`);
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
    bulkCreateVerses
  };
};
