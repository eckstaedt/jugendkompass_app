import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { logActivity } from '@/lib/activity-logger';
import { CreatePostParams } from './types';

export const useCreatePost = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (params: CreatePostParams) => {
      const { title, content, category, editionId, authorId, published, imageUrl } = params;
      
      const { data: result, error } = await supabase
        .from('posts')
        .insert([
          { 
            title, 
            content, 
            category,
            edition_id: editionId,
            author_id: authorId,
            published,
            image_url: imageUrl
          }
        ])
        .select()
        .single();

      if (error) {
        console.error("Error creating post:", error);
        throw error;
      }

      // Update the logActivity call to use the correct parameters
      if (result.data) {
        await logActivity(
          params.authorId,
          'post',
          'create',
          result.data.id,
          `Post "${params.title}" created`
        );
      }
      
      return result;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
    onError: (error: any) => {
      console.error("Error creating post:", error);
    }
  });
};
