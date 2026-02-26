
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
    mutationFn: async ({ title, description, file, url, userId }: { title: string, description?: string, file?: File, url?: string, userId: string }) => {
      try {
        // First create a content entry
        const { data: contentData, error: contentError } = await supabase
          .from('content')
          .insert({ content_type: 'video', status: 'published' })
          .select('id')
          .single();

        if (contentError) throw contentError;

        let videoUrl: string;

        if (file) {
          // Upload file to Supabase storage
          const fileExt = file.name.split('.').pop();
          const fileName = `${Math.random()}.${fileExt}`;
          const { error: storageError } = await supabase.storage
            .from('videos')
            .upload(`public/${fileName}`, file, {
              cacheControl: '3600',
              upsert: false
            });

          if (storageError) {
            console.error('Storage error:', storageError);
            throw storageError;
          }

          const { data: { publicUrl } } = supabase.storage
            .from('videos')
            .getPublicUrl(`public/${fileName}`);

          videoUrl = publicUrl;
        } else if (url) {
          videoUrl = url;
        } else {
          throw new Error('Either file or url must be provided');
        }

        // Insert video record with the content_id
        const { data: videoData, error: insertError } = await supabase
          .from('videos')
          .insert({ 
            title, 
            description: description || null,
            url: videoUrl, 
            user_id: userId,
            content_id: contentData.id
          })
          .select('*, content:content_id(*)')
          .single();

        if (insertError) throw insertError;

        if (videoData && videoData.id) {
          await logActivity(
            userId,
            'video',
            'create',
            String(videoData.id),
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
