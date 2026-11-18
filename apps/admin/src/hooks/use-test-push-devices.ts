import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

export type TestPushDevice = {
  id: string;
  label: string;
  fcm_token: string;
  platform: string | null;
  language: string;
  created_by: string | null;
  created_at: string;
};

export type TestPushResult = {
  id: string;
  label: string;
  ok: boolean;
  status: number;
  error?: string;
};

export const useTestPushDevices = () =>
  useQuery({
    queryKey: ['test-push-devices'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('test_push_devices' as any)
        .select('*')
        .order('created_at', { ascending: false });
      if (error) throw error;
      return (data ?? []) as unknown as TestPushDevice[];
    },
  });

export const useCreateTestPushDevice = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: {
      label: string;
      fcm_token: string;
      platform?: string | null;
      language: string;
    }) => {
      const { data: userData } = await supabase.auth.getUser();
      const { data, error } = await supabase
        .from('test_push_devices' as any)
        .insert({ ...payload, created_by: userData.user?.id ?? null })
        .select()
        .single();
      if (error) throw error;
      return data as unknown as TestPushDevice;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['test-push-devices'] }),
  });
};

export const useUpdateTestPushDevice = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      id,
      ...patch
    }: {
      id: string;
      label?: string;
      fcm_token?: string;
      platform?: string | null;
      language?: string;
    }) => {
      const { data, error } = await supabase
        .from('test_push_devices' as any)
        .update(patch)
        .eq('id', id)
        .select()
        .single();
      if (error) throw error;
      return data as unknown as TestPushDevice;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['test-push-devices'] }),
  });
};

export const useDeleteTestPushDevice = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('test_push_devices' as any)
        .delete()
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['test-push-devices'] }),
  });
};

export const useSendTestPush = () =>
  useMutation({
    mutationFn: async (payload: {
      device_ids: string[];
      title: string;
      body: string;
      data?: Record<string, string>;
      image_url?: string | null;
    }) => {
      const { data, error } = await supabase.functions.invoke('send-test-push', {
        body: payload,
      });
      if (error) throw error;
      return data as { results: TestPushResult[] };
    },
  });
