
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Video } from '@/lib/supabase';

export const useVideos = () => {
  return useQuery({
    queryKey: ['videos'],
    queryFn: async () => {
      const { data: videos, error } = await supabase
        .from('videos')
        .select('*')
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
      // Upload file to Supabase storage
      const fileExt = file.name.split('.').pop();
      const fileName = `${userId}/${Math.random()}.${fileExt}`;
      const { error: storageError } = await supabase.storage
        .from('videos')
        .upload(fileName, file);

      if (storageError) throw storageError;

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('videos')
        .getPublicUrl(fileName);

      // Insert video record
      const { data: videoData, error: insertError } = await supabase
        .from('videos')
        .insert({ 
          title, 
          url: publicUrl, 
          user_id: userId 
        })
        .select();

      if (insertError) throw insertError;

      return videoData[0];
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['videos'] });
    }
  });
};
