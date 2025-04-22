
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { logActivity } from '@/lib/activity-logger';
import { CreatePostParams } from '../use-posts';

export function useCreatePost() {
  const queryClient = useQueryClient();

  return useMutation({
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
}
