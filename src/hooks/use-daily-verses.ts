
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { DailyVerse } from '@/lib/supabase';
import { logActivity } from '@/lib/activity-logger';

export const useDailyVerses = () => {
  const { data: verses = [], isLoading, error } = useQuery({
    queryKey: ['dailyVerses'],
    queryFn: async () => {
      const { data: dailyVerses, error } = await supabase
        .from('verse_of_the_day')
        .select('*, content:content_id(*)')
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

  return {
    verses,
    isLoading,
    error,
    createVerse,
    updateVerse
  };
};
