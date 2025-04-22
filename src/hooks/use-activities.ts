
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";

export type Activity = {
  id: string;
  user_id: string;
  action_type: string;
  entity_type: string;
  entity_id?: string;
  description: string;
  created_at: string;
};

export const useActivities = () => {
  return useQuery({
    queryKey: ['activities'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('activities')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(3);

      if (error) throw error;
      return data as Activity[];
    },
  });
};
