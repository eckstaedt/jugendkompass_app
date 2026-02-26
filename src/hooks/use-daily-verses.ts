import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { DailyVerse } from '@/lib/supabase';
import { logActivity } from '@/lib/activity-logger';

export const useDailyVerses = () => {
  const { data: verses = [], isLoading, error } = useQuery({
    queryKey: ['dailyVerses'],
    queryFn: async () => {
      // Explicitly use the specific foreign key relationship
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
        .order('date', { ascending: false });

      if (error) {
        console.error('Supabase error:', error);
        throw new Error(error.message);
      }
      
      // Explicitly cast the data to resolve type issues
      return dailyVerses as unknown as DailyVerse[];
    },
  });

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
    createVerse,
    updateVerse,
    bulkCreateVerses
  };
};
