
import { supabase } from '@/integrations/supabase/client';
import { logActivity } from './activity-logger';

export const fetchUsers = async () => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching users:', error);
      throw error;
    }

    return data || [];
  } catch (err) {
    console.error('Unexpected error fetching users:', err);
    throw err;
  }
};

export const createUser = async (email: string, password?: string) => {
  try {
    const { data, error } = await supabase.auth.signUp({
      email: email,
      password: password || 'changeme',
      options: {
        data: {
          role: 'user',
        }
      }
    });

    if (error) {
      console.error('Error creating user:', error);
      return { error: error.message };
    }

    return { data };
  } catch (err) {
    console.error('Unexpected error creating user:', err);
    return { error: 'Unexpected error during user creation.' };
  }
};

export const deleteUser = async (userId: string) => {
  try {
    const { error } = await supabase.auth.admin.deleteUser(userId);

    if (error) {
      console.error('Error deleting user:', error);
      return { error: error.message };
    }

    return { success: true };
  } catch (err) {
    console.error('Unexpected error deleting user:', err);
    return { error: 'Unexpected error during user deletion.' };
  }
};

export const updateUserRole = async (userId: string, role: string, adminId?: string) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .update({ role })
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      console.error('Error updating user role:', error);
      return { error: error.message };
    }

    if (adminId) {
      await logActivity(
        adminId,
        'user',
        'update',
        userId,
        `User role updated to ${role}`
      );
    }
    
    return { data };
  } catch (error) {
    console.error('Unexpected error updating user role:', error);
    return { error: 'Unexpected error during user role update.' };
  }
};
