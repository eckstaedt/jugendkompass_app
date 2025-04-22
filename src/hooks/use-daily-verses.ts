import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { logActivity } from '@/lib/activity-logger';

export type DailyVerse = {
  id: string;
  verse: string;
  reference: string;
  date: string;
  content_id?: string;
};

export function useDailyVerses() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  const { data: verses = [], isLoading } = useQuery({
    queryKey: ['daily-verses'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('verse_of_the_day')
        .select('*, content:content_id(*)')
        .order('date', { ascending: true });
      
      if (error) throw error;
      return data as DailyVerse[];
    },
  });

  const logVerseActivity = async (action: 'create' | 'update', verseId: string | null, date: string) => {
    try {
      await logActivity({
        action_type: action,
        entity_type: 'verse',
        entity_id: verseId,
        description: `Tagesvers für ${date} ${action === 'create' ? 'erstellt' : 'aktualisiert'}`,
      });
    } catch (error) {
      console.error(`Error logging ${action} activity:`, error);
    }
  };

  const createVerse = useMutation({
    mutationFn: async (verse: Omit<DailyVerse, 'id'>) => {
      try {
        const { data, error } = await supabase
          .from('verse_of_the_day')
          .insert({
            date: verse.date,
            verse: verse.verse,
            reference: verse.reference
          })
          .select('*, content:content_id(*)')
          .single();

        if (error) {
          if (error.code === '23505' && error.message.includes('verse_of_the_day_date_key')) {
            throw new Error('Ein Vers für dieses Datum existiert bereits');
          }
          throw error;
        }
        
        if (data) {
          await logVerseActivity('create', data.id, verse.date);
        }
        
        return data;
      } catch (error) {
        console.error('Error creating verse:', error);
        throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['daily-verses'] });
      toast({
        title: "Vers hinzugefügt",
        description: "Der Tagesvers wurde erfolgreich hinzugefügt.",
      });
    },
    onError: (error) => {
      toast({
        title: "Fehler",
        description: error.message || "Der Tagesvers konnte nicht hinzugefügt werden.",
        variant: "destructive",
      });
      console.error('Error creating verse:', error);
    },
  });

  const updateVerse = useMutation({
    mutationFn: async ({ id, ...verse }: DailyVerse) => {
      try {
        const { data, error } = await supabase
          .from('verse_of_the_day')
          .update(verse)
          .eq('id', id)
          .select('*, content:content_id(*)')
          .single();

        if (error) throw error;
        
        await logVerseActivity('update', id, verse.date);
        
        return data;
      } catch (error) {
        console.error('Error updating verse:', error);
        throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['daily-verses'] });
      toast({
        title: "Vers aktualisiert",
        description: "Der Tagesvers wurde erfolgreich aktualisiert.",
      });
    },
    onError: (error) => {
      toast({
        title: "Fehler",
        description: "Der Tagesvers konnte nicht aktualisiert werden.",
        variant: "destructive",
      });
      console.error('Error updating verse:', error);
    },
  });

  return {
    verses,
    isLoading,
    createVerse,
    updateVerse,
  };
}
