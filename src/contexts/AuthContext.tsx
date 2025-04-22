
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

  useEffect(() => {
    // Set up auth state listener first to avoid missing events
    const { data: authListener } = supabase.auth.onAuthStateChange(async (event, session) => {
      console.log("Auth state changed:", event, session?.user?.id);
      
      if (event === 'SIGNED_IN' && session?.user) {
        try {
          const { data: userData, error } = await supabase
            .from('users')
            .select('*')
            .eq('id', session.user.id)
            .single();
          
          if (error) {
            console.error("Error fetching user data after sign in:", error);
            toast({
              title: "Fehler beim Abrufen der Benutzerdaten",
              description: "Bitte versuche es erneut oder kontaktiere den Administrator.",
              variant: "destructive",
            });
            await supabase.auth.signOut();
            setUser(null);
            setIsAdmin(false);
            navigate('/login');
          } else if (userData && userData.role === 'admin') {
            console.log("Admin user signed in:", userData);
            setUser(userData as User);
            setIsAdmin(true);
            toast({
              title: "Erfolgreich angemeldet",
              description: "Willkommen im Admin-Dashboard",
              variant: "success",
            });
          } else {
            console.log("User signed in but is not an admin:", userData);
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
          console.error("Unexpected error during auth state change:", error);
          toast({
            title: "Unerwarteter Fehler",
            description: "Bitte versuche es später erneut.",
            variant: "destructive",
          });
          await supabase.auth.signOut();
          setUser(null);
          setIsAdmin(false);
          navigate('/login');
        }
      } else if (event === 'SIGNED_OUT') {
        setUser(null);
        setIsAdmin(false);
        navigate('/login');
      }
    });

    // Then check for existing session
    const checkUser = async () => {
      setLoading(true);
      
      try {
        const { data: { session }} = await supabase.auth.getSession();
        
        if (session?.user) {
          try {
            const { data: userData, error } = await supabase
              .from('users')
              .select('*')
              .eq('id', session.user.id)
              .single();
            
            if (error) {
              console.error("Error fetching user data:", error);
              await supabase.auth.signOut();
              setUser(null);
              setIsAdmin(false);
            } else if (userData && userData.role === 'admin') {
              setUser(userData as User);
              setIsAdmin(true);
            } else {
              console.log("User exists but is not an admin:", userData);
              await supabase.auth.signOut();
              setUser(null);
              setIsAdmin(false);
            }
          } catch (error) {
            console.error("Unexpected error checking user:", error);
            await supabase.auth.signOut();
            setUser(null);
            setIsAdmin(false);
          }
        } else {
          setUser(null);
          setIsAdmin(false);
        }
      } catch (error) {
        console.error("Error checking session:", error);
        setUser(null);
        setIsAdmin(false);
      } finally {
        setLoading(false);
      }
    };

    checkUser();

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, [navigate, toast]);

  const login = async (email: string, password: string) => {
    try {
      console.log("Logging in with email:", email);
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      
      if (error) {
        console.error("Login error:", error);
        return { error, data: null };
      }
      
      if (data.user) {
        console.log("User authenticated successfully:", data.user.id);
        // The role check will be handled by the onAuthStateChange listener
        return { data, error: null };
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
