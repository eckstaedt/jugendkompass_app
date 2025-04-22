
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Video } from '@/lib/supabase';
import { logActivity } from '@/lib/activity-logger';

export const useVideos = () => {
  return useQuery({
    queryKey: ['videos'],
    queryFn: async () => {
      const { data: videos, error } = await supabase
        .from('videos')
        .select('*, content:content_id(*)')
        .order('created_at', { ascending: false });
      
      if (error) throw error;
      return videos as Video[];
    },
  });
};

export const useUploadVideo = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ title, file, userId }: { title: string, file: File, userId: string }) => {
      try {
        // First create a content entry
        const { data: contentData, error: contentError } = await supabase
          .from('content')
          .insert({ content_type: 'video', status: 'published' })
          .select('id')
          .single();

        if (contentError) throw contentError;

        // Upload file to Supabase storage
        const fileExt = file.name.split('.').pop();
        const fileName = `${Math.random()}.${fileExt}`;
        const { error: storageError, data } = await supabase.storage
          .from('videos')
          .upload(`public/${fileName}`, file, {
            cacheControl: '3600',
            upsert: false
          });

        if (storageError) {
          console.error('Storage error:', storageError);
          throw storageError;
        }

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('videos')
          .getPublicUrl(`public/${fileName}`);

        // Insert video record with the content_id
        const { data: videoData, error: insertError } = await supabase
          .from('videos')
          .insert({ 
            title, 
            url: publicUrl, 
            user_id: userId,
            content_id: contentData.id
          })
          .select('*, content:content_id(*)')
          .single();

        if (insertError) throw insertError;

        // Log the activity - Make sure video ID is properly converted to string
        if (videoData && videoData.id) {
          await logActivity(
            userId,
            'video',
            'create',
            String(videoData.id), // Ensure ID is properly converted to string
            `Video '${title}' created`
          );
        }

        return videoData;
      } catch (error) {
        console.error('Error in upload process:', error);
        throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['videos'] });
    }
  });
};
