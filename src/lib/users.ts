
import { supabase } from "@/integrations/supabase/client";
import { logActivity } from "./activity-logger";

export type User = {
  id: string;
  email: string;
  created_at: string;
  role: 'admin' | 'user';
};

export async function fetchUsers(): Promise<User[]> {
  const { data: users, error } = await supabase
    .from('users')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching users:', error);
    throw error;
  }

  // Ensure that the role is properly typed
  return (users || []).map(user => ({
    ...user,
    role: (user.role === 'admin' ? 'admin' : 'user') as 'admin' | 'user'
  }));
}

export async function updateUserRole(userId: string, role: 'admin' | 'user') {
  const { error } = await supabase
    .from('user_roles')
    .upsert({ user_id: userId, role }, { onConflict: 'user_id' });

  if (error) {
    console.error('Error updating user role:', error);
    throw error;
  }

  await logActivity({
    action_type: 'update',
    entity_type: 'user',
    entity_id: userId,
    description: `Benutzerrolle auf ${role} geändert`
  });
}
