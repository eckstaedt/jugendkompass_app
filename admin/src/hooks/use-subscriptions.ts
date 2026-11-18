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
  paid: boolean;
  paid_at: string | null;
  paid_by: string | null;
  created_at: string;
  updated_at: string;
};

export type SubscriptionInput = Omit<
  Subscription,
  'id' | 'created_at' | 'updated_at' | 'paid' | 'paid_at' | 'paid_by'
> & {
  paid?: boolean;
};

export const useSubscriptions = () =>
  useQuery({
    queryKey: ['subscriptions'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('subscriptions')
        .select('*')
        .order('created_at', { ascending: false });
      if (error) throw error;
      return (data ?? []) as Subscription[];
    },
  });

export const useCreateSubscription = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: SubscriptionInput) => {
      const { data, error } = await supabase
        .from('subscriptions')
        .insert(input)
        .select()
        .single();
      if (error) throw error;
      return data as Subscription;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['subscriptions'] }),
  });
};

export const useDeleteSubscription = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('subscriptions')
        .delete()
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['subscriptions'] }),
  });
};

export const useUpdateSubscriptionPaid = () => {
  const qc = useQueryClient();
  return useMutation({
    // paid_at / paid_by / updated_at werden per DB-Trigger gesetzt
    mutationFn: async ({ id, paid }: { id: string; paid: boolean }) => {
      const { data, error } = await supabase
        .from('subscriptions')
        .update({ paid })
        .eq('id', id)
        .select()
        .single();
      if (error) throw error;
      return data as Subscription;
    },
    onMutate: async ({ id, paid }) => {
      await qc.cancelQueries({ queryKey: ['subscriptions'] });
      const previous = qc.getQueryData<Subscription[]>(['subscriptions']);
      qc.setQueryData<Subscription[]>(['subscriptions'], (old) =>
        old?.map((s) =>
          s.id === id
            ? { ...s, paid, paid_at: paid ? new Date().toISOString() : null }
            : s,
        ),
      );
      return { previous };
    },
    onError: (_err, _vars, ctx) => {
      if (ctx?.previous) qc.setQueryData(['subscriptions'], ctx.previous);
    },
    onSettled: () => qc.invalidateQueries({ queryKey: ['subscriptions'] }),
  });
};
