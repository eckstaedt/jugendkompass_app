
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useToast } from '@/hooks/use-toast';
import { 
  BookIcon, 
  EyeIcon, 
  EyeOffIcon, 
  LoaderCircleIcon, 
  AlertCircleIcon,
  ShieldAlertIcon
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { 
  Card, 
  CardContent, 
  CardDescription, 
  CardFooter, 
  CardHeader, 
  CardTitle 
} from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';

const loginSchema = z.object({
  email: z.string().email('Bitte gib eine gültige E-Mail-Adresse ein.'),
  password: z.string().min(6, 'Das Passwort muss mindestens 6 Zeichen lang sein.')
});

type LoginFormValues = z.infer<typeof loginSchema>;

const LoginPage = () => {
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const { login } = useAuth();
  const navigate = useNavigate();
  const { toast } = useToast();

  const form = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: ''
    }
  });

  const handleLogin = async (values: LoginFormValues) => {
    setErrorMessage(null);
    setLoading(true);
    
    try {
      console.log("Attempting login for:", values.email);
      const { error } = await login(values.email, values.password);
      
      if (error) {
        console.error("Login error:", error);
        let errorMsg = 'Bitte überprüfe deine Anmeldedaten und versuche es erneut.';
        
        if (error.message) {
          if (error.message.includes('Invalid login credentials')) {
            errorMsg = 'Ungültige Anmeldedaten. Bitte überprüfe deine E-Mail und dein Passwort.';
          } else if (error.message.includes('Email not confirmed')) {
            errorMsg = 'Deine E-Mail-Adresse wurde noch nicht bestätigt. Bitte prüfe deinen Posteingang.';
          } else if (error.message.includes('rate limit')) {
            errorMsg = 'Zu viele Anmeldeversuche. Bitte versuche es später erneut.';
          } else if (error.message.includes('not an admin')) {
            errorMsg = 'Du hast keine Administratorrechte für dieses Dashboard.';
          } else if (error.message.includes('User not found')) {
            errorMsg = 'Benutzer nicht gefunden. Bitte überprüfe deine E-Mail.';
          } else {
            // Use the actual error message if it's not one of the above
            errorMsg = `Fehler: ${error.message}`;
          }
        }
        
        setErrorMessage(errorMsg);
        toast({
          title: 'Anmeldung fehlgeschlagen',
          description: errorMsg,
          variant: 'destructive',
        });
      } else {
        // Success case will be handled by the auth state change listener
        console.log("Login successful, redirecting...");
      }
    } catch (error: any) {
      console.error('Unexpected login error:', error);
      setErrorMessage('Ein unerwarteter Fehler ist aufgetreten. Bitte versuche es später erneut.');
      toast({
        title: 'Unerwarteter Fehler',
        description: 'Ein unerwarteter Fehler ist aufgetreten. Bitte versuche es später erneut.',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-gradient-to-b from-blue-50 to-white p-4">
      <div className="w-full max-w-md">
        <div className="mb-8 flex justify-center">
          <div className="flex items-center space-x-2">
            <BookIcon className="h-10 w-10 text-primary" />
            <h1 className="text-3xl font-bold text-gray-800">Jugendkompass Admin</h1>
          </div>
        </div>
        
        <Card className="border-none shadow-lg">
          <CardHeader className="space-y-1">
            <CardTitle className="text-2xl">Anmelden</CardTitle>
            <CardDescription className="text-base">
              Gib deine Zugangsdaten ein, um auf das Admin-Dashboard zuzugreifen.
            </CardDescription>
          </CardHeader>
          
          {errorMessage && (
            <CardContent className="pt-0 pb-0">
              <Alert variant="destructive">
                <AlertCircleIcon className="h-4 w-4" />
                <AlertTitle>Anmeldungsfehler</AlertTitle>
                <AlertDescription>{errorMessage}</AlertDescription>
              </Alert>
            </CardContent>
          )}
          
          <Form {...form}>
            <form onSubmit={form.handleSubmit(handleLogin)}>
              <CardContent className="space-y-4">
                <FormField
                  control={form.control}
                  name="email"
                  render={({ field }) => (
                    <FormItem className="space-y-2">
                      <FormLabel className="text-base">E-Mail</FormLabel>
                      <FormControl>
                        <Input
                          {...field}
                          type="email"
                          placeholder="admin@beispiel.de"
                          disabled={loading}
                          className="h-12 text-base"
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="password"
                  render={({ field }) => (
                    <FormItem className="space-y-2">
                      <FormLabel className="text-base">Passwort</FormLabel>
                      <FormControl>
                        <div className="relative">
                          <Input
                            {...field}
                            type={showPassword ? "text" : "password"}
                            placeholder="••••••••"
                            disabled={loading}
                            className="h-12 text-base pr-12"
                          />
                          <Button
                            type="button"
                            variant="ghost"
                            size="icon"
                            className="absolute right-0 top-0 h-12"
                            onClick={() => setShowPassword(!showPassword)}
                          >
                            {showPassword ? (
                              <EyeOffIcon className="h-5 w-5" />
                            ) : (
                              <EyeIcon className="h-5 w-5" />
                            )}
                            <span className="sr-only">
                              {showPassword ? "Passwort verbergen" : "Passwort anzeigen"}
                            </span>
                          </Button>
                        </div>
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </CardContent>
              
              <CardFooter className="flex flex-col space-y-4">
                <Button
                  type="submit"
                  className="w-full h-12 text-base font-semibold"
                  disabled={loading}
                >
                  {loading ? (
                    <div className="flex items-center justify-center space-x-2">
                      <LoaderCircleIcon className="h-5 w-5 animate-spin" />
                      <span>Anmelden...</span>
                    </div>
                  ) : (
                    "Anmelden"
                  )}
                </Button>
                
                {loading && (
                  <div className="w-full">
                    <Progress value={100} className="animate-pulse h-1" />
                    <p className="text-sm text-center text-muted-foreground mt-1">
                      Verbindung zum Authentifizierungsserver wird hergestellt...
                    </p>
                  </div>
                )}
              </CardFooter>
            </form>
          </Form>
          
          <CardFooter className="pt-0 flex flex-col">
            <div className="text-sm text-muted-foreground mt-4">
              <div className="flex items-center justify-center mb-2">
                <ShieldAlertIcon className="h-4 w-4 mr-1" />
                <span>Administratorzugang erforderlich</span>
              </div>
              <p className="text-center">
                Nur Benutzer mit Administratorrechten können sich hier anmelden.
              </p>
            </div>
          </CardFooter>
        </Card>
      </div>
    </div>
  );
};

export default LoginPage;
