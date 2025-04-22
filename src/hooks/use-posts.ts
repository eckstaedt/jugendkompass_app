
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from './use-toast';
import { logActivity } from '@/lib/activity-logger';

export type Post = {
  id: string;
  title: string;
  body: string;
  category_id: string;
  edition_id: string;
  content_id: string | null;
  audio_id: string | null;
  image_url: string | null;
};

type CreatePostParams = {
  title: string;
  body: string;
  category_id: string;
  edition_id: string;
  status: 'active' | 'draft';
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
        .order('id');

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

  const { mutate: createPost } = useMutation({
    mutationFn: async (postData: CreatePostParams) => {
      // Create content first
      const { data: contentData, error: contentError } = await supabase
        .from('content')
        .insert({ 
          content_type: 'post', 
          status: postData.status
        })
        .select('id')
        .single();

      if (contentError) throw contentError;

      // Then create post with content_id
      const { data: postResult, error: postError } = await supabase
        .from('posts')
        .insert({
          title: postData.title,
          body: postData.body,
          category_id: postData.category_id,
          edition_id: postData.edition_id,
          content_id: contentData.id
        })
        .select()
        .single();

      if (postError) throw postError;

      // Log activity
      await logActivity({
        action_type: 'create',
        entity_type: 'post',
        entity_id: postResult.id,
        description: `Neuer Beitrag erstellt: ${postData.title}`
      });

      return postResult;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    }
  });

  return { 
    posts, 
    isLoading, 
    deletePost,
    createPost 
  };
}
