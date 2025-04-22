
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/hooks/use-toast';

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
      const { data, error } = await supabase
        .from('verse_of_the_day')
        .insert([verse])
        .select()
        .single();

      if (error) throw error;
      return data;
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
      const { data, error } = await supabase
        .from('verse_of_the_day')
        .update(verse)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
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
