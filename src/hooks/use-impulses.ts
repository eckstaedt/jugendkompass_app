
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { v4 as uuidv4 } from 'uuid';

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
    mutationFn: async ({ date, impulse_text, image }: { date: string; impulse_text: string; image: File }) => {
      // First upload the image
      const fileExt = image.name.split('.').pop();
      const fileName = `${uuidv4()}.${fileExt}`;
      const { error: uploadError, data: uploadData } = await supabase.storage
        .from('impulses')
        .upload(fileName, image);

      if (uploadError) throw uploadError;

      const image_url = `${supabase.storageUrl}/object/public/impulses/${fileName}`;

      // Then create the impulse
      const { data, error } = await supabase
        .from('impulses')
        .insert([{ date, impulse_text, image_url }])
        .select()
        .single();

      if (error) throw error;
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
    mutationFn: async ({ id, ...impulse }: { id: string; date: string; impulse_text: string; image_url?: string }) => {
      const { data, error } = await supabase
        .from('impulses')
        .update(impulse)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['impulses'] });
    },
  });
};
