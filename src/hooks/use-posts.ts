
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from './use-toast';

export type Post = {
  id: string;
  title: string;
  body: string;
  category_id: string | null;
  edition_id: string | null;
  created_at: string;
  image_url: string | null;
};

export function usePosts() {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: posts = [], isLoading } = useQuery({
    queryKey: ['posts'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('posts')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data as Post[];
    }
  });

  const { mutate: deletePost } = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('posts')
        .delete()
        .eq('id', id);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
      toast({
        title: "Erfolg",
        description: "Beitrag wurde gelöscht",
        variant: "success",
      });
    },
    onError: () => {
      toast({
        title: "Fehler",
        description: "Beitrag konnte nicht gelöscht werden",
        variant: "destructive",
      });
    }
  });

  return { posts, isLoading, deletePost };
}
