
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useToast } from '@/hooks/use-toast';
import { BookIcon, EyeIcon, EyeOffIcon, LoaderCircleIcon } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';

const LoginPage = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();
  const { toast } = useToast();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!email || !password) {
      toast({
        title: 'Eingabefehler',
        description: 'Bitte gib deine E-Mail-Adresse und dein Passwort ein.',
        variant: 'destructive',
      });
      return;
    }
    
    setLoading(true);
    
    try {
      const { error } = await login(email, password);
      
      if (error) {
        throw error;
      }
      
      toast({
        title: 'Erfolgreich angemeldet',
        description: 'Willkommen im Jugendkompass Admin-Dashboard',
        variant: 'success',
      });
      
      navigate('/dashboard');
    } catch (error: any) {
      console.error('Login error:', error);
      let errorMessage = 'Bitte überprüfe deine Anmeldedaten und versuche es erneut.';
      
      if (error.message) {
        if (error.message.includes('Invalid login credentials')) {
          errorMessage = 'Ungültige Anmeldedaten. Bitte überprüfe deine E-Mail und dein Passwort.';
        } else if (error.message.includes('Email not confirmed')) {
          errorMessage = 'Deine E-Mail-Adresse wurde noch nicht bestätigt. Bitte prüfe deinen Posteingang.';
        } else if (error.message.includes('rate limit')) {
          errorMessage = 'Zu viele Anmeldeversuche. Bitte versuche es später erneut.';
        }
      }
      
      toast({
        title: 'Anmeldung fehlgeschlagen',
        description: errorMessage,
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-gray-50 p-4">
      <div className="w-full max-w-md">
        <div className="mb-8 flex justify-center">
          <div className="flex items-center space-x-2">
            <BookIcon className="h-8 w-8 text-primary" />
            <h1 className="text-2xl font-bold">Jugendkompass Admin</h1>
          </div>
        </div>
        
        <Card>
          <CardHeader>
            <CardTitle>Anmelden</CardTitle>
            <CardDescription>
              Gib deine Zugangsdaten ein, um auf das Admin-Dashboard zuzugreifen.
            </CardDescription>
          </CardHeader>
          <form onSubmit={handleLogin}>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="email">E-Mail</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="admin@beispiel.de"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={loading}
                  required
                />
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="password">Passwort</Label>
                <div className="relative">
                  <Input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    disabled={loading}
                    required
                  />
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="absolute right-0 top-0"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? (
                      <EyeOffIcon className="h-4 w-4" />
                    ) : (
                      <EyeIcon className="h-4 w-4" />
                    )}
                    <span className="sr-only">
                      {showPassword ? "Passwort verbergen" : "Passwort anzeigen"}
                    </span>
                  </Button>
                </div>
              </div>
            </CardContent>
            
            <CardFooter>
              <Button
                type="submit"
                className="w-full"
                disabled={loading}
              >
                {loading ? (
                  <div className="flex items-center justify-center space-x-2">
                    <LoaderCircleIcon className="h-4 w-4 animate-spin" />
                    <span>Anmelden...</span>
                  </div>
                ) : (
                  "Anmelden"
                )}
              </Button>
            </CardFooter>
          </form>
        </Card>
      </div>
    </div>
  );
};

export default LoginPage;
