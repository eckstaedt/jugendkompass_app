
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { logActivity } from '@/lib/activity-logger';
import { useToast } from '@/hooks/use-toast';
import { UpdatePostStatusParams } from './types';

export const useUpdatePostStatus = () => {
  const queryClient = useQueryClient();
  const { toast } = useToast();
  
  return useMutation({
    mutationFn: async ({ id, status, userId }: UpdatePostStatusParams) => {
      // First get the content_id from the post
      const { data: post, error: postError } = await supabase
        .from('posts')
        .select('content_id')
        .eq('id', id)
        .single();

      if (postError) {
        console.error('Error fetching post:', postError);
        throw postError;
      }

      if (!post.content_id) {
        console.error('Post has no content_id:', id);
        throw new Error('Post has no associated content');
      }
        
      // Update the status in the content table
      const { data, error } = await supabase
        .from('content')
        .update({ status })
        .eq('id', post.content_id)
        .select()
        .single();

      if (error) {
        console.error('Error updating post status:', error);
        throw error;
      }

      // Log the activity with German description
      await logActivity(
        userId,
        'post',
        'update',
        id,
        `Beitragsstatus auf "${status}" geändert`
      );
      
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
      toast({
        title: "Erfolg",
        description: "Beitragsstatus wurde aktualisiert",
        variant: "success",
      });
    },
    onError: (error) => {
      console.error("Status update error:", error);
      toast({
        title: "Fehler",
        description: "Status konnte nicht aktualisiert werden",
        variant: "destructive",
      });
    }
  });
};
