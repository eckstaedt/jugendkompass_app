
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { BookIcon } from 'lucide-react';

const Index = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Kurze Verzögerung, um einen Ladeeffekt zu simulieren
    const timer = setTimeout(() => {
      setLoading(false);
    }, 1000);
    
    return () => clearTimeout(timer);
  }, []);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50">
      {loading ? (
        <div className="flex flex-col items-center">
          <div className="w-12 h-12 rounded-full border-4 border-primary border-t-transparent animate-spin"></div>
          <p className="mt-4 text-lg text-gray-600">Lade Jugendkompass...</p>
        </div>
      ) : (
        <div className="w-full max-w-md p-8 space-y-8">
          <div className="flex flex-col items-center text-center">
            <BookIcon className="h-16 w-16 text-primary" />
            <h1 className="mt-4 text-3xl font-bold">Jugendkompass Admin</h1>
            <p className="mt-2 text-gray-600">
              Das Verwaltungsportal für den Jugendkompass
            </p>
          </div>
          
          <div className="flex flex-col gap-4">
            <Button 
              className="w-full py-6 text-lg"
              onClick={() => {
                // Navigiere zur Login-Seite
                navigate('/login');
              }}
            >
              Zum Admin-Login
            </Button>
            
            <div className="text-center text-sm text-gray-500">
              <p>Nur für autorisierte Benutzer zugänglich.</p>
              <p>© {new Date().getFullYear()} Jugendkompass</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Index;
