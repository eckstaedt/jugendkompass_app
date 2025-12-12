
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { v4 as uuidv4 } from 'uuid';
import { logActivity } from '@/lib/activity-logger';

export type Impulse = {
  id: string;
  content_id: string;
  date: string;
  impulse_text: string;
  image_url: string;
  content?: {
    status: string;
    created_at: string;
  };
};

type CreateImpulseArgs = {
  date: string;
  impulse_text: string;
  image: File;
  user_id: string;
};

type UpdateImpulseArgs = {
  id: string;
  date: string;
  impulse_text: string;
  image_url?: string;
  user_id: string;
};

export const useImpulses = () => {
  return useQuery({
    queryKey: ['impulses'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('impulses')
        .select(`
          *,
          content (
            status,
            created_at
          )
        `)
        .order('date', { ascending: false });

      if (error) throw error;
      return data as Impulse[];
    },
  });
};

export const useCreateImpulse = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ date, impulse_text, image, user_id }: CreateImpulseArgs) => {
      // First upload the image
      const fileExt = image.name.split('.').pop();
      const fileName = `${uuidv4()}.${fileExt}`;
      const { error: uploadError } = await supabase.storage
        .from('impulses')
        .upload(fileName, image);

      if (uploadError) throw uploadError;

      // Get the public URL for the uploaded image
      const { data: { publicUrl } } = supabase.storage
        .from('impulses')
        .getPublicUrl(fileName);

      // First, create a content record to get the content_id
      const { data: contentData, error: contentError } = await supabase
        .from('content')
        .insert([{ content_type: 'impulse', status: 'published' }])
        .select()
        .single();
      
      if (contentError) throw contentError;
      
      // Then create the impulse with the generated content_id
      const { data, error } = await supabase
        .from('impulses')
        .insert([{ 
          content_id: contentData.id,
          date, 
          impulse_text, 
          image_url: publicUrl 
        }])
        .select()
        .single();

      if (error) throw error;

      // Log the creation of a new impulse
      if (user_id && data?.id) {
        await logActivity(
          user_id,
          'impulse',
          'create',
          data.id,
          `Impuls erstellt`
        );
      }
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['impulses'] });
    },
  });
};

export const useUpdateImpulse = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, user_id, ...impulse }: UpdateImpulseArgs) => {
      const { data, error } = await supabase
        .from('impulses')
        .update(impulse)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;

      // Log the update of an impulse
      if (user_id) {
        await logActivity(
          user_id,
          'impulse',
          'update',
          id,
          `Impuls bearbeitet`
        );
      }

      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['impulses'] });
    },
  });
};

export const useDeleteImpulse = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, content_id, user_id }: { id: string; content_id: string; user_id: string }) => {
      // Delete the impulse first (will cascade from content)
      const { error: contentError } = await supabase
        .from('content')
        .delete()
        .eq('id', content_id);

      if (contentError) throw contentError;

      // Log the deletion
      if (user_id) {
        await logActivity(
          user_id,
          'impulse',
          'delete',
          id,
          `Impuls gelöscht`
        );
      }

      return { id };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['impulses'] });
    },
  });
};
