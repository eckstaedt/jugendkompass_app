import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

export type ShippingMethod = 'standard' | 'pickup';

export type Subscription = {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string | null;
  street: string;
  postal_code: string;
  city: string;
  country: string;
  address_extra: string | null;
  shipping_method: ShippingMethod;
  created_at: string;
  updated_at: string;
};

export type SubscriptionInput = Omit<Subscription, 'id' | 'created_at' | 'updated_at'>;

export const useSubscriptions = () =>
  useQuery({
    queryKey: ['subscriptions'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('subscriptions' as any)
        .select('*')
        .order('created_at', { ascending: false });
      if (error) throw error;
      return (data ?? []) as unknown as Subscription[];
    },
  });

export const useCreateSubscription = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: SubscriptionInput) => {
      const { data, error } = await supabase
        .from('subscriptions' as any)
        .insert(input as any)
        .select()
        .single();
      if (error) throw error;
      return data as unknown as Subscription;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['subscriptions'] }),
  });
};

export const useDeleteSubscription = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('subscriptions' as any)
        .delete()
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['subscriptions'] }),
  });
};
