
import { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { useNavigate } from 'react-router-dom';
import { User } from '@/lib/supabase';
import { useToast } from '@/hooks/use-toast';

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

  // Separate function to check admin status
  const checkAdminStatus = async (userId: string) => {
    try {
      const { data: userData, error } = await supabase
        .from('users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

      if (error) throw error;
      return userData?.role === 'admin';
    } catch (error) {
      console.error('Error checking admin status:', error);
      return false;
    }
  };

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        console.log("Auth state changed:", event, session?.user?.id);
        
        if (session?.user) {
          // First set the basic user state
          setUser(session.user);
          
          // Then check admin status in a separate call
          const isUserAdmin = await checkAdminStatus(session.user.id);
          setIsAdmin(isUserAdmin);
          
          if (isUserAdmin) {
            toast({
              title: "Erfolgreich angemeldet",
              description: "Willkommen im Admin-Dashboard",
              variant: "success",
            });
            navigate('/dashboard');
          } else {
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
        setUser(session.user);
        const isUserAdmin = await checkAdminStatus(session.user.id);
        setIsAdmin(isUserAdmin);
        if (!isUserAdmin) {
          await supabase.auth.signOut();
          setUser(null);
          setIsAdmin(false);
          navigate('/login');
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
