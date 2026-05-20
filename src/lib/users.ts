
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

interface CreateUserParams {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  role: 'admin' | 'user';
}

export const createUser = async ({ email, password, firstName, lastName, role }: CreateUserParams) => {
  try {
    const { data, error } = await supabase.functions.invoke('create-user', {
      body: { email, password, firstName, lastName, role },
    });

    if (error) {
      console.error('Error creating user:', error);
      return { error: error.message };
    }

    if (data?.error) {
      return { error: data.error };
    }

    return { data };
  } catch (err) {
    console.error('Unexpected error creating user:', err);
    return { error: 'Unexpected error during user creation.' };
  }
};

export const deleteUser = async (userId: string) => {
  try {
    const { data, error } = await supabase.functions.invoke('delete-user', {
      body: { userId }
    });

    if (error) {
      console.error('Error deleting user:', error);
      return { error: error.message };
    }

    if (data?.error) {
      console.error('Error from delete-user function:', data.error);
      return { error: data.error };
    }

    return { success: true };
  } catch (err) {
    console.error('Unexpected error deleting user:', err);
    return { error: 'Unerwarteter Fehler beim Löschen des Benutzers.' };
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
        `Benutzerrolle auf "${role}" geändert`
      );
    }
    
    return { data };
  } catch (error) {
    console.error('Unexpected error updating user role:', error);
    return { error: 'Unexpected error during user role update.' };
  }
};
