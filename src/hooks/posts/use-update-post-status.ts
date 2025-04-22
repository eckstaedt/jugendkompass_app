
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { logActivity } from '@/lib/activity-logger';
import { UpdatePostStatusParams } from './types';

export const useUpdatePostStatus = () => {
  const queryClient = useQueryClient();
  
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

      // Log the activity
      await logActivity(
        userId,
        'post',
        'update',
        id,
        `Post status set to ${status}`
      );
      
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
  });
};
