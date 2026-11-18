
import { createContext, useContext, useEffect, useState, useRef, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { useNavigate } from 'react-router-dom';
import { User } from '@/lib/supabase';
import { useToast } from '@/hooks/use-toast';
import { Session, User as SupabaseUser } from '@supabase/supabase-js';

type AuthContextType = {
  user: User | null;
  loading: boolean;
  adminChecked: boolean;
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
  const [adminChecked, setAdminChecked] = useState(false);
  const navigate = useNavigate();
  const { toast } = useToast();
  const navigateRef = useRef(navigate);
  const toastRef = useRef(toast);
  const initialSessionDoneRef = useRef(false);
  const processingAuthRef = useRef(false);

  useEffect(() => {
    navigateRef.current = navigate;
    toastRef.current = toast;
  });

  const convertSupabaseUser = (supabaseUser: SupabaseUser | null): User | null => {
    if (!supabaseUser) return null;
    return {
      id: supabaseUser.id,
      email: supabaseUser.email || '',
      role: 'user',
      created_at: supabaseUser.created_at || new Date().toISOString()
    };
  };

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

  const handleAuthSession = useCallback(async (session: Session | null, isLogin: boolean) => {
    if (processingAuthRef.current) return;
    processingAuthRef.current = true;

    try {
      if (session?.user) {
        const customUser = convertSupabaseUser(session.user);
        setUser(customUser);
        setAdminChecked(false);

        const isUserAdmin = await checkAdminStatus(session.user.id);
        setIsAdmin(isUserAdmin);
        setAdminChecked(true);

        if (isUserAdmin) {
          if (isLogin) {
            console.log("Login successful, navigating to dashboard");
            navigateRef.current('/dashboard');
          }
        } else {
          toastRef.current({
            title: "Zugriff verweigert",
            description: "Du hast keine Administrator-Berechtigungen.",
            variant: "destructive",
          });
          await supabase.auth.signOut();
          setUser(null);
          setIsAdmin(false);
          navigateRef.current('/login');
        }
      } else {
        setUser(null);
        setIsAdmin(false);
        setAdminChecked(true);
      }
    } catch (error) {
      console.error("Error in auth handling:", error);
      setUser(null);
      setIsAdmin(false);
      setAdminChecked(true);
    } finally {
      processingAuthRef.current = false;
    }
  }, []);

  useEffect(() => {
    // First check initial session
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      await handleAuthSession(session, false);
      setLoading(false);
      initialSessionDoneRef.current = true;
    });

    // Then set up listener for subsequent changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, session) => {
        console.log("Auth state changed:", event, session?.user?.id);

        if (event === 'SIGNED_IN' && initialSessionDoneRef.current) {
          // Only process as a real login if we don't already have a user
          // (tab switch / visibility change also fires SIGNED_IN)
          if (!user) {
            handleAuthSession(session, true);
          }
        } else if (event === 'SIGNED_OUT') {
          setUser(null);
          setIsAdmin(false);
          setAdminChecked(true);
          navigateRef.current('/login');
        } else if (event === 'TOKEN_REFRESHED') {
          // Just update user data, don't navigate or reset admin state
          if (session?.user) {
            setUser(convertSupabaseUser(session.user));
          }
        }
        // Ignore INITIAL_SESSION - handled by getSession() above
      }
    );

    return () => {
      subscription.unsubscribe();
    };
  }, [handleAuthSession, user]);

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
    <AuthContext.Provider value={{ user, loading, adminChecked, login, logout, isAdmin }}>
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
