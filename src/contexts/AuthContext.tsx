
import { createContext, useContext, useEffect, useState, useRef } from 'react';
import { supabase } from '@/lib/supabase';
import { useNavigate } from 'react-router-dom';
import { User } from '@/lib/supabase';
import { useToast } from '@/hooks/use-toast';
import { Session, User as SupabaseUser } from '@supabase/supabase-js';

type AuthContextType = {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<{
    error: Error | null;
    data: any | null;
  }>;
  logout: () => Promise<void>;
  isAdmin: boolean;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [isAdmin, setIsAdmin] = useState(false);
  const navigate = useNavigate();
  const { toast } = useToast();

  // Helper function to convert Supabase User to our custom User type
  const convertSupabaseUser = (supabaseUser: SupabaseUser | null): User | null => {
    if (!supabaseUser) return null;
    return {
      id: supabaseUser.id,
      email: supabaseUser.email || '',
      role: 'user', // Default role, will be updated after checking admin status
      created_at: supabaseUser.created_at || new Date().toISOString()
    };
  };

  // Separate function to check admin status
  const checkAdminStatus = async (userId: string) => {
    try {
      console.log("Checking admin status for user:", userId);
      const { data: userData, error } = await supabase
        .from('users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

      if (error) {
        console.error('Error checking admin status:', error);
        return false;
      }
      
      console.log("Admin check result:", userData);
      return userData?.role === 'admin';
    } catch (error) {
      console.error('Exception checking admin status:', error);
      return false;
    }
  };

  useEffect(() => {
    // First set up the auth state change listener
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, session) => {
        console.log("Auth state changed:", event, session?.user?.id);
        
        if (session?.user) {
          // Convert the Supabase user to our custom User type
          const customUser = convertSupabaseUser(session.user);
          setUser(customUser);
          
          // Check admin status in a separate timeout to avoid recursion
          setTimeout(async () => {
            try {
              const isUserAdmin = await checkAdminStatus(session.user.id);
              setIsAdmin(isUserAdmin);
              
              if (isUserAdmin && event === 'SIGNED_IN') {
                // Removed the success toast message here
                navigate('/dashboard');
              } else if (!isUserAdmin) {
                toast({
                  title: "Zugriff verweigert",
                  description: "Du hast keine Administrator-Berechtigungen.",
                  variant: "destructive",
                });
                await supabase.auth.signOut();
                setUser(null);
                setIsAdmin(false);
                navigate('/login');
              }
            } catch (error) {
              console.error("Error in admin check:", error);
              setUser(null);
              setIsAdmin(false);
              navigate('/login');
            }
          }, 0);
        } else {
          setUser(null);
          setIsAdmin(false);
          if (event === 'SIGNED_OUT') {
            navigate('/login');
          }
        }
      }
    );

    // Check initial session
    supabase.auth.getSession().then(async ({ data: { session }}) => {
      if (session?.user) {
        const customUser = convertSupabaseUser(session.user);
        setUser(customUser);
        
        try {
          const isUserAdmin = await checkAdminStatus(session.user.id);
          setIsAdmin(isUserAdmin);
          if (!isUserAdmin) {
            await supabase.auth.signOut();
            setUser(null);
            setIsAdmin(false);
            navigate('/login');
          }
        } catch (error) {
          console.error("Error checking admin status:", error);
          setUser(null);
          setIsAdmin(false);
        }
      }
      setLoading(false);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [navigate, toast]);

  const login = async (email: string, password: string) => {
    try {
      console.log("Logging in with email:", email);
      const { data, error } = await supabase.auth.signInWithPassword({ 
        email, 
        password 
      });
      
      if (error) {
        console.error("Login error:", error);
        return { error, data: null };
      }
      
      return { data, error: null };
    } catch (error: any) {
      console.error("Unexpected error during login:", error);
      return { error, data: null };
    }
  };

  const logout = async () => {
    await supabase.auth.signOut();
    toast({
      title: "Abgemeldet",
      description: "Du wurdest erfolgreich abgemeldet.",
    });
    navigate('/login');
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, isAdmin }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
