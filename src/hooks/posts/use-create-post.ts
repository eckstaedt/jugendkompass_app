
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { logActivity } from '@/lib/activity-logger';
import { CreatePostParams } from './types';

export const useCreatePost = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (params: CreatePostParams) => {
      const { title, body, category_id, edition_id, status, author_id, image_url } = params;
      
      // First create a content entry
      const { data: contentData, error: contentError } = await supabase
        .from('content')
        .insert({ 
          content_type: 'post',
          status: status
        })
        .select()
        .single();

      if (contentError) {
        console.error("Error creating content:", contentError);
        throw contentError;
      }

      // Then create the post with reference to the content
      const { data: postData, error: postError } = await supabase
        .from('posts')
        .insert([
          { 
            title, 
            body,
            category_id,
            edition_id,
            content_id: contentData.id,
            image_url
          }
        ])
        .select()
        .single();

      if (postError) {
        console.error("Error creating post:", postError);
        throw postError;
      }

      // Log the activity if an author ID was provided
      if (author_id) {
        await logActivity(
          author_id,
          'post',
          'create',
          postData.id,
          `Post "${title}" created`
        );
      }
      
      return postData;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
    onError: (error: any) => {
      console.error("Error creating post:", error);
    }
  });
};
