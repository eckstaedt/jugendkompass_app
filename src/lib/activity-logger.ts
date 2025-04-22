
import { supabase } from '@/integrations/supabase/client';

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
    
    // Validate entityId is either a valid UUID or null/undefined
    let finalEntityId = entityId;
    
    // Check if entityId is a number or numeric string (like "2") and
    // handle it properly to avoid SQL errors
    if (entityId && !isValidUUID(entityId)) {
      console.log(`Converting non-UUID entity ID: ${entityId} to null`);
      finalEntityId = null; // Set to null if not a valid UUID
    }
    
    const { error } = await supabase.from('activities').insert({
      user_id: userId,
      entity_type: entityType,
      action_type: actionType,
      entity_id: finalEntityId,
      description: description || `${actionType} ${entityType}`,
    });

    if (error) {
      console.error('Error logging activity:', error);
    }
  } catch (err) {
    console.error('Error in activity logger:', err);
  }
};

// Helper function to validate UUID format
function isValidUUID(str: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(str);
}
