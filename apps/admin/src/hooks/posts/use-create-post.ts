
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { logActivity } from '@/lib/activity-logger';
import { CreatePostParams } from './types';

export const useCreatePost = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (params: CreatePostParams) => {
      const { title, body, category_id, edition_id, status, author_id, image_url, audioFile } = params;
      
      // Upload audio if provided
      let audio_id: string | null = null;
      if (audioFile) {
        const fileExt = audioFile.name.split('.').pop();
        const fileName = `${crypto.randomUUID()}.${fileExt}`;
        const { error: uploadError } = await supabase.storage
          .from('audios')
          .upload(fileName, audioFile);
        if (uploadError) throw uploadError;

        const { data: { publicUrl } } = supabase.storage
          .from('audios')
          .getPublicUrl(fileName);

        const { data: audioData, error: audioError } = await supabase
          .from('audios')
          .insert({ url: publicUrl })
          .select('id')
          .single();
        if (audioError) throw audioError;
        audio_id = audioData.id;
      }

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
            image_url,
            audio_id
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
          `Beitrag "${title}" erstellt`
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
