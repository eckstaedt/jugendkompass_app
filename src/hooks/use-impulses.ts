
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

export type Impulse = {
  id: string;
  content_id: string;
  date: string;
  impulse_text: string;
  image_url: string | null;
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
    mutationFn: async (impulse: { date: string; impulse_text: string; image_url?: string }) => {
      const { data, error } = await supabase
        .from('impulses')
        .insert([impulse])
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
