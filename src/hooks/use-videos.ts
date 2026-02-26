
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

        // Insert video record — the DB trigger handle_video_content() creates the content entry automatically
        const { data: videoData, error: insertError } = await supabase
          .from('videos')
          .insert({ 
            title, 
            description: description || null,
            url: videoUrl, 
            user_id: userId,
            content_id: '00000000-0000-0000-0000-000000000000' // placeholder, overwritten by trigger
          } as any)
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

export const useUpdateVideo = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, title, description, url }: { id: number, title: string, description?: string, url?: string }) => {
      const updateData: Record<string, any> = { title, description: description || null };
      if (url) updateData.url = url;

      const { data, error } = await supabase
        .from('videos')
        .update(updateData)
        .eq('id', id)
        .select('*, content:content_id(*)')
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['videos'] });
    }
  });
};

export const useDeleteVideo = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: number) => {
      const { error } = await supabase
        .from('videos')
        .delete()
        .eq('id', id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['videos'] });
    }
  });
};
