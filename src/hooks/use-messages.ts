
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { v4 as uuidv4 } from 'uuid';

export type Message = {
  id: number;
  content_id: string | null;
  created_by: string | null;
  created_at: string | null;
  message: string;
  image_url: string | null;
};

export const useMessages = () => {
  return useQuery({
    queryKey: ['messages'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('messages')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data as Message[];
    },
  });
};

export const useCreateMessage = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ message, imageFile }: { message: string; imageFile?: File }) => {
      let image_url = null;

      if (imageFile) {
        const fileExt = imageFile.name.split('.').pop();
        const fileName = `${uuidv4()}.${fileExt}`;
        const { error: uploadError, data } = await supabase.storage
          .from('messages')
          .upload(fileName, imageFile);

        if (uploadError) throw uploadError;
        
        const { data: { publicUrl } } = supabase.storage
          .from('messages')
          .getPublicUrl(fileName);
          
        image_url = publicUrl;
      }

      const { data, error } = await supabase
        .from('messages')
        .insert([{ message, image_url }])
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
  });
};

export const useUpdateMessage = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, message, imageFile }: { id: number; message: string; imageFile?: File }) => {
      let image_url = undefined;

      if (imageFile) {
        const fileExt = imageFile.name.split('.').pop();
        const fileName = `${uuidv4()}.${fileExt}`;
        const { error: uploadError } = await supabase.storage
          .from('messages')
          .upload(fileName, imageFile);

        if (uploadError) throw uploadError;
        
        const { data: { publicUrl } } = supabase.storage
          .from('messages')
          .getPublicUrl(fileName);
          
        image_url = publicUrl;
      }

      const { data, error } = await supabase
        .from('messages')
        .update({ message, ...(image_url ? { image_url } : {}) })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
  });
};

export const useDeleteMessage = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: number) => {
      const { error } = await supabase
        .from('messages')
        .delete()
        .eq('id', id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
  });
};
