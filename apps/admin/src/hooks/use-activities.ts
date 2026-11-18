
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
  // Add user information fields
  user_first_name?: string;
  user_last_name?: string;
};

export const useActivities = () => {
  return useQuery({
    queryKey: ['activities'],
    queryFn: async () => {
      // Join with users table to get first and last names
      // Specify the foreign key relationship to use
      const { data, error } = await supabase
        .from('activities')
        .select(`
          *,
          users!activities_user_id_fkey (
            firstName,
            lastName
          )
        `)
        .order('created_at', { ascending: false })
        .limit(3);

      if (error) throw error;
      
      // Transform the data to include user information directly in the activity object
      const activitiesWithUserInfo = data.map(activity => ({
        ...activity,
        user_first_name: activity.users?.firstName || '',
        user_last_name: activity.users?.lastName || ''
      }));
      
      return activitiesWithUserInfo as Activity[];
    },
  });
};
