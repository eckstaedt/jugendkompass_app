
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/hooks/use-toast';
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

export type CreatePostParams = {
  title: string;
  body: string;
  category_id: string;
  edition_id: string;
  status: 'draft' | 'published';
};

export function usePosts() {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: posts = [], isLoading } = useQuery({
    queryKey: ['posts'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('posts')
        .select('*, content(status)')
        .order('id');

      if (error) throw error;
      return data as (Post & { content: { status: 'draft' | 'published' } })[];
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
      const { data: contentData, error: contentError } = await supabase
        .from('content')
        .insert({ 
          content_type: 'post', 
          status: postData.status
        })
        .select('id')
        .single();

      if (contentError) throw contentError;

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

  const { mutate: updatePost } = useMutation({
    mutationFn: async ({ id, data }: { id: string; data: { title: string; body: string } }) => {
      const { error } = await supabase
        .from('posts')
        .update({ title: data.title, body: data.body })
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

  const { mutate: updatePostStatus } = useMutation({
    mutationFn: async ({ contentId, status }: { contentId: string, status: 'draft' | 'published' }) => {
      console.log('Updating post status:', { contentId, status });
      
      if (!contentId) {
        throw new Error('Content ID is required to update post status');
      }
      
      // Get current content record to verify it exists
      const { data: existingContent, error: fetchError } = await supabase
        .from('content')
        .select('*')
        .eq('id', contentId)
        .maybeSingle();
        
      if (fetchError) {
        console.error('Error fetching content:', fetchError);
        throw fetchError;
      }
      
      if (!existingContent) {
        throw new Error(`Content with ID ${contentId} not found`);
      }
      
      // Now update the content status
      const { error } = await supabase
        .from('content')
        .update({ status })
        .eq('id', contentId);

      if (error) {
        console.error('Error updating post status:', error);
        throw error;
      }

      await logActivity({
        action_type: 'update',
        entity_type: 'post',
        entity_id: contentId,
        description: `Post status updated to ${status}`
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
      toast({
        title: "Status aktualisiert",
        description: "Der Status des Beitrags wurde erfolgreich aktualisiert",
        variant: "success",
      });
    },
    onError: (error) => {
      console.error('Error in updatePostStatus mutation:', error);
      toast({
        title: "Fehler",
        description: "Der Status konnte nicht aktualisiert werden. Bitte überprüfen Sie die Konsole für Details.",
        variant: "destructive",
      });
    }
  });

  return {
    posts, 
    isLoading, 
    deletePost,
    createPost,
    updatePost,
    updatePostStatus
  };
}
