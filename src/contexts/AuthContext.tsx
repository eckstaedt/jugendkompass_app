
import { createContext, useContext, useEffect, useState } from 'react';
import { supabase, User } from '@/lib/supabase';
import { useNavigate } from 'react-router-dom';

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

  useEffect(() => {
    // Überprüfe, ob ein Benutzer angemeldet ist, wenn die Anwendung geladen wird
    const checkUser = async () => {
      setLoading(true);
      
      const { data: { session }} = await supabase.auth.getSession();
      
      if (session?.user) {
        // Benutzerrolle aus der users-Tabelle abrufen
        const { data: userData, error } = await supabase
          .from('users')
          .select('*')
          .eq('id', session.user.id)
          .single();
        
        if (userData && userData.role === 'admin') {
          setUser(userData as User);
          setIsAdmin(true);
        } else {
          // Wenn der Benutzer kein Admin ist, abmelden
          await supabase.auth.signOut();
          setUser(null);
          setIsAdmin(false);
        }
      } else {
        setUser(null);
        setIsAdmin(false);
      }
      
      setLoading(false);
    };

    checkUser();

    // Auth-Änderungen überwachen
    const { data: authListener } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_IN' && session?.user) {
        // Benutzerrolle überprüfen
        const { data: userData, error } = await supabase
          .from('users')
          .select('*')
          .eq('id', session.user.id)
          .single();
        
        if (userData && userData.role === 'admin') {
          setUser(userData as User);
          setIsAdmin(true);
        } else {
          // Wenn der Benutzer kein Admin ist, abmelden
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

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, [navigate]);

  const login = async (email: string, password: string) => {
    return supabase.auth.signInWithPassword({ email, password });
  };

  const logout = async () => {
    await supabase.auth.signOut();
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
    throw new Error('useAuth muss innerhalb eines AuthProviders verwendet werden');
  }
  return context;
};
