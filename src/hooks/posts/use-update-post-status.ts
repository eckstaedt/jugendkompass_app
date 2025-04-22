import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { logActivity } from '@/lib/activity-logger';

export const useUpdatePostStatus = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ id, published, userId }: { id: string; published: boolean; userId: string }) => {
      const { data, error } = await supabase
        .from('posts')
        .update({ published })
        .eq('id', id)
        .select()
        .single();

      if (error) {
        console.error('Error updating post status:', error);
        throw error;
      }

      // Update the logActivity call to use the correct parameters
      await logActivity(
        userId,
        'post',
        'update',
        id,
        `Post status set to ${published ? 'published' : 'draft'}`
      );
      
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
  });
};
