
import { supabase } from './supabase';

type EntityType = 'post' | 'poll' | 'video' | 'daily_verse' | 'notification' | 'user';
type ActionType = 'create' | 'update' | 'delete';

export const logActivity = async (
  userId: string,
  entityType: EntityType,
  actionType: ActionType,
  entityId?: string,
  description?: string
) => {
  try {
    // Only log important user actions (create, update, delete)
    if (!['create', 'update', 'delete'].includes(actionType)) {
      return;
    }
    
    const { error } = await supabase.from('activities').insert({
      user_id: userId,
      entity_type: entityType,
      action_type: actionType,
      entity_id: entityId,
      description: description || `${actionType} ${entityType}`,
    });

    if (error) {
      console.error('Error logging activity:', error);
    }
  } catch (err) {
    console.error('Error in activity logger:', err);
  }
};
