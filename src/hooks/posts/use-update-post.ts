
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/hooks/use-toast';
import { UpdatePostParams } from '../use-posts';

export function useUpdatePost() {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, data }: UpdatePostParams) => {
      const { error } = await supabase
        .from('posts')
        .update({ 
          title: data.title, 
          body: data.body,
          audio_id: data.audio_id 
        })
        .eq('id', id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
      toast({
        title: "Erfolg",
        description: "Beitrag wurde aktualisiert",
        variant: "success",
      });
    },
    onError: () => {
      toast({
        title: "Fehler",
        description: "Beitrag konnte nicht aktualisiert werden",
        variant: "destructive",
      });
    }
  });
}
