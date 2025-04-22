
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from './use-toast';

export type Edition = {
  id: string;
  name: string;
  published_at: string | null;
};

export function useEditions() {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: editions = [], isLoading } = useQuery({
    queryKey: ['editions'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('editions')
        .select('*')
        .order('name');

      if (error) throw error;
      return data as Edition[];
    }
  });

  const { mutate: createEdition } = useMutation({
    mutationFn: async (name: string) => {
      const { error } = await supabase
        .from('editions')
        .insert([{ name }]);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['editions'] });
      toast({
        title: "Erfolg",
        description: "Edition wurde erstellt",
        variant: "success",
      });
    },
    onError: () => {
      toast({
        title: "Fehler",
        description: "Edition konnte nicht erstellt werden",
        variant: "destructive",
      });
    }
  });

  return { editions, isLoading, createEdition };
}
