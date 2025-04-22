
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Video } from '@/lib/supabase';

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
      // Upload file to Supabase storage using a unique filename
      const fileExt = file.name.split('.').pop();
      const fileName = `${Math.random()}.${fileExt}`; // Remove userId subfolder
      const { error: storageError } = await supabase.storage
        .from('videos')
        .upload(fileName, file);

      if (storageError) throw storageError;

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('videos')
        .getPublicUrl(fileName);

      // First create a content entry
      const { data: contentData, error: contentError } = await supabase
        .from('content')
        .insert({ content_type: 'video', status: 'published' })
        .select('id')
        .single();

      if (contentError) throw contentError;

      // Then insert video record with the content_id
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

      return videoData;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['videos'] });
    }
  });
};
