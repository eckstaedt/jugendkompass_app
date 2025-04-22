
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { useAuth } from '@/contexts/AuthContext';
import { usePolls } from '@/hooks/use-polls';
import { format } from 'date-fns';
import { de } from 'date-fns/locale';
import { PlusIcon } from 'lucide-react';

const PollsPage = () => {
  const [showAll, setShowAll] = useState(false);
  const { isAdmin } = useAuth();
  const navigate = useNavigate();
  const { data: polls, isLoading } = usePolls(showAll);

  return (
    <DashboardLayout title="Umfragen">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Umfragen verwalten</h2>
          <p className="text-muted-foreground">
            Alle Umfragen im Überblick.
          </p>
        </div>
        <div className="flex items-center gap-4">
          <div className="flex items-center space-x-2">
            <Switch
              checked={showAll}
              onCheckedChange={setShowAll}
              id="show-all"
            />
            <label htmlFor="show-all" className="text-sm">
              Alle Umfragen anzeigen
            </label>
          </div>
          {isAdmin && (
            <Button onClick={() => navigate('new')}>
              <PlusIcon className="mr-2 h-4 w-4" />
              Neue Umfrage
            </Button>
          )}
        </div>
      </div>

      {isLoading ? (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3].map((i) => (
            <Card key={i} className="animate-pulse">
              <CardHeader className="h-24 bg-muted" />
              <CardContent className="h-32 bg-muted mt-4" />
            </Card>
          ))}
        </div>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {polls?.map((poll) => (
            <Card 
              key={poll.id} 
              className="cursor-pointer transition-colors hover:bg-accent/50"
              onClick={() => navigate(`${poll.id}`)}
            >
              <CardHeader>
                <CardTitle className="line-clamp-2">{poll.question}</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex flex-col gap-2 text-sm text-muted-foreground">
                  <p>Erstellt am {format(new Date(poll.created_at), "dd. MMMM yyyy", { locale: de })}</p>
                  {poll.expires_at && (
                    <p>Läuft bis {format(new Date(poll.expires_at), "dd. MMMM yyyy", { locale: de })}</p>
                  )}
                  <div className="mt-2">
                    <span className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                      poll.is_active 
                        ? "bg-green-100 text-green-700" 
                        : "bg-red-100 text-red-700"
                    }`}>
                      {poll.is_active ? "Aktiv" : "Inaktiv"}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </DashboardLayout>
  );
};

export default PollsPage;
