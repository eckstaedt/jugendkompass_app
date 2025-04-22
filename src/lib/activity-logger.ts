
import { supabase } from "@/integrations/supabase/client";

type LogActivityParams = {
  action_type: string;
  entity_type: string;
  entity_id?: string;
  description: string;
};

export const logActivity = async ({
  action_type,
  entity_type,
  entity_id,
  description,
}: LogActivityParams) => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      console.error('No user found when trying to log activity');
      return;
    }

    const { error } = await supabase
      .from('activities')
      .insert({
        user_id: user.id,
        action_type,
        entity_type,
        entity_id,
        description,
      });

    if (error) {
      console.error('Error logging activity:', error);
    }
  } catch (error) {
    console.error('Unexpected error in logActivity:', error);
  }
};
