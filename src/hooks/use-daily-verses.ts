import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { DailyVerse } from '@/lib/supabase';
import { logActivity } from '@/lib/activity-logger';

export const useDailyVerses = () => {
  return useQuery({
    queryKey: ['dailyVerses'],
    queryFn: async () => {
      const { data: dailyVerses, error } = await supabase
        .from('daily_verses')
        .select('*, content:content_id(*)')
        .order('date', { ascending: false });

      if (error) {
        console.error('Supabase error:', error);
        throw new Error(error.message);
      }
      return dailyVerses as DailyVerse[];
    },
  });
};

export const useCreateDailyVerse = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ verse, reference, date, userId }: { verse: string; reference: string; date: string; userId: string }) => {
      const { data: contentData, error: contentError } = await supabase
        .from('content')
        .insert({ content_type: 'daily_verse', status: 'published' })
        .select('id')
        .single();

      if (contentError) throw contentError;

      const { data: result, error } = await supabase
        .from('daily_verses')
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
};
