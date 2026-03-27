
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { v4 as uuidv4 } from 'uuid';
import { logActivity } from '@/lib/activity-logger';

export type Message = {
  id: number;
  content_id: string | null;
  created_by: string | null;
  created_at: string | null;
  title: string | null;
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
    mutationFn: async ({ title, message, imageFile, userId }: { title?: string; message: string; imageFile?: File; userId?: string }) => {
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
        .insert([{ title: title || null, message, image_url }])
        .select()
        .single();

      if (error) throw error;

      if (userId && data?.id) {
        await logActivity(
          userId,
          'message',
          'create',
          String(data.id),
          'Nachricht erstellt'
        );
      }

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
    mutationFn: async ({ id, title, message, imageFile, userId }: { id: number; title?: string; message: string; imageFile?: File; userId?: string }) => {
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
        .update({ title: title || null, message, ...(image_url ? { image_url } : {}) })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;

      if (userId) {
        await logActivity(
          userId,
          'message',
          'update',
          String(id),
          'Nachricht bearbeitet'
        );
      }

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
    mutationFn: async ({ id, userId }: { id: number; userId?: string }) => {
      const { error } = await supabase
        .from('messages')
        .delete()
        .eq('id', id);

      if (error) throw error;

      if (userId) {
        await logActivity(
          userId,
          'message',
          'delete',
          String(id),
          'Nachricht gelöscht'
        );
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['messages'] });
    },
  });
};
