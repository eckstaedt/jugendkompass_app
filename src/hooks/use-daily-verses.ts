
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
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
        .select('*')
        .order('date', { ascending: true });
      
      if (error) throw error;
      return data as DailyVerse[];
    },
  });

  const createVerse = useMutation({
    mutationFn: async (verse: Omit<DailyVerse, 'id'>) => {
      try {
        // First do the database insert with minimal fields
        const { data, error } = await supabase
          .from('verse_of_the_day')
          .insert({
            date: verse.date,
            verse: verse.verse,
            reference: verse.reference
          })
          .select()
          .single();

        if (error) throw error;
        
        // Only log activity after the insert succeeds
        await logActivity({
          action_type: 'create',
          entity_type: 'verse',
          entity_id: data.id,
          description: `Tagesvers für ${verse.date} erstellt`,
        });
        
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
        description: "Der Tagesvers konnte nicht hinzugefügt werden.",
        variant: "destructive",
      });
      console.error('Error creating verse:', error);
    },
  });

  const updateVerse = useMutation({
    mutationFn: async ({ id, ...verse }: DailyVerse) => {
      try {
        // First do the database update with minimal fields
        const { data, error } = await supabase
          .from('verse_of_the_day')
          .update({
            date: verse.date,
            verse: verse.verse,
            reference: verse.reference
          })
          .eq('id', id)
          .select()
          .single();

        if (error) throw error;
        
        // Only log activity after the update succeeds
        await logActivity({
          action_type: 'update',
          entity_type: 'verse',
          entity_id: id,
          description: `Tagesvers für ${verse.date} aktualisiert`,
        });
        
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
