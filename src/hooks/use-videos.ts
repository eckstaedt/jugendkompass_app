
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Video } from '@/lib/supabase';
import { logActivity } from '@/lib/activity-logger';

import { usePreviewLocale } from '@/contexts/PreviewLocaleContext';

export const useVideos = () => {
  const { previewLang } = usePreviewLocale();
  return useQuery({
    queryKey: ['videos', previewLang],
    queryFn: async () => {
      if (previewLang !== 'de') {
        const { data: localized, error: rpcError } = await supabase
          .rpc('get_videos_localized', { lang: previewLang });
        if (rpcError) throw rpcError;
        const contentIds = (localized ?? []).map((v: any) => v.content_id).filter(Boolean);
        let contentMap: Record<string, any> = {};
        if (contentIds.length) {
          const { data: contents } = await supabase
            .from('content')
            .select('*')
            .in('id', contentIds);
          contentMap = Object.fromEntries((contents ?? []).map((c: any) => [c.id, c]));
        }
        const merged = [...(localized ?? [])]
          .map((v: any) => ({ ...v, content: contentMap[v.content_id] }))
          .sort((a: any, b: any) => (b.created_at ?? '').localeCompare(a.created_at ?? ''));
        return merged as Video[];
      }
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
    mutationFn: async ({ title, description, file, url, imageUrl, userId, createdAt }: { title: string, description?: string, file?: File, url?: string, imageUrl: string, userId: string, createdAt?: string }) => {
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

        // Create content entry first
        const { data: contentData, error: contentError } = await supabase
          .from('content')
          .insert({ content_type: 'video', status: 'published' })
          .select()
          .single();

        if (contentError) throw contentError;

        const insertPayload: Record<string, any> = { 
          title, 
          description: description || null,
          url: videoUrl,
          image_url: imageUrl,
          user_id: userId,
          content_id: contentData.id,
        };
        if (createdAt) insertPayload.created_at = createdAt;

        const { data: videoData, error: insertError } = await supabase
          .from('videos')
          .insert(insertPayload)
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
    mutationFn: async ({ id, title, description, url, imageUrl }: { id: number, title: string, description?: string, url?: string, imageUrl?: string }) => {
      const updateData: Record<string, any> = { title, description: description || null };
      if (url) updateData.url = url;
      if (imageUrl !== undefined) updateData.image_url = imageUrl;

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
