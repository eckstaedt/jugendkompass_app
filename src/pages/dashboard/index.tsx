
import React from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { BarChart2Icon, BookIcon, FileTextIcon, PieChartIcon, UsersIcon, FileVideoIcon, CalendarIcon, BellIcon } from 'lucide-react';

// Dashboard-Karten-Typ
type DashboardCardProps = {
  title: string;
  value: string | number;
  description: string;
  icon: React.ReactNode;
  className?: string;
};

// Dashboard-Karten-Komponente
const DashboardCard = ({ title, value, description, icon, className }: DashboardCardProps) => (
  <Card className={className}>
    <CardHeader className="flex flex-row items-center justify-between pb-2">
      <CardTitle className="text-sm font-medium">{title}</CardTitle>
      {icon}
    </CardHeader>
    <CardContent>
      <div className="text-2xl font-bold">{value}</div>
      <p className="text-xs text-muted-foreground">{description}</p>
    </CardContent>
  </Card>
);

const DashboardPage = () => {
  return (
    <DashboardLayout title="Dashboard">
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <DashboardCard 
          title="Beiträge" 
          value="24" 
          description="12 neue Beiträge im letzten Monat" 
          icon={<FileTextIcon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Umfragen" 
          value="8" 
          description="2 aktive Umfragen" 
          icon={<PieChartIcon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Videos" 
          value="16" 
          description="4 neue Videos im letzten Monat" 
          icon={<FileVideoIcon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Tagesverse" 
          value="365" 
          description="30 neue Verse im letzten Monat" 
          icon={<CalendarIcon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Benutzer" 
          value="1.254" 
          description="120 neue Benutzer im letzten Monat" 
          icon={<UsersIcon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Statistiken" 
          value="5.783" 
          description="Aufrufe im letzten Monat" 
          icon={<BarChart2Icon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Benachrichtigungen" 
          value="12" 
          description="3 Benachrichtigungen im letzten Monat" 
          icon={<BellIcon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Editionen" 
          value="4" 
          description="Ausgaben des Jugendkompass im Jahr" 
          icon={<BookIcon className="h-5 w-5 text-primary" />} 
        />
      </div>
      
      <div className="mt-8 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <Card className="col-span-full lg:col-span-2">
          <CardHeader>
            <CardTitle>Neueste Aktivitäten</CardTitle>
            <CardDescription>
              Die letzten Aktivitäten im Admin-Dashboard
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center gap-4 rounded-md border p-4">
                <FileTextIcon className="h-5 w-5 text-primary" />
                <div className="flex-1 space-y-1">
                  <p className="text-sm font-medium leading-none">
                    Neuer Beitrag erstellt
                  </p>
                  <p className="text-sm text-muted-foreground">
                    "Gottes Plan für dein Leben" in Kategorie "Glaube"
                  </p>
                </div>
                <div className="text-sm text-muted-foreground">
                  Vor 35 Minuten
                </div>
              </div>
              
              <div className="flex items-center gap-4 rounded-md border p-4">
                <PieChartIcon className="h-5 w-5 text-primary" />
                <div className="flex-1 space-y-1">
                  <p className="text-sm font-medium leading-none">
                    Umfrage aktualisiert
                  </p>
                  <p className="text-sm text-muted-foreground">
                    "Wie oft liest du in der Bibel?" - Neue Antwortmöglichkeit hinzugefügt
                  </p>
                </div>
                <div className="text-sm text-muted-foreground">
                  Vor 2 Stunden
                </div>
              </div>
              
              <div className="flex items-center gap-4 rounded-md border p-4">
                <BellIcon className="h-5 w-5 text-primary" />
                <div className="flex-1 space-y-1">
                  <p className="text-sm font-medium leading-none">
                    Benachrichtigung gesendet
                  </p>
                  <p className="text-sm text-muted-foreground">
                    "Neue Ausgabe verfügbar" an alle Benutzer
                  </p>
                </div>
                <div className="text-sm text-muted-foreground">
                  Vor 5 Stunden
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader>
            <CardTitle>Kommende Aufgaben</CardTitle>
            <CardDescription>
              Anstehende Aufgaben für das Dashboard
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-start gap-4">
                <div className="mt-0.5 h-5 w-5 rounded-full border-2 border-primary"></div>
                <div className="space-y-1">
                  <p className="text-sm font-medium leading-none">
                    Tagesvers für morgen erstellen
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Fällig heute
                  </p>
                </div>
              </div>
              
              <div className="flex items-start gap-4">
                <div className="mt-0.5 h-5 w-5 rounded-full border-2 border-primary"></div>
                <div className="space-y-1">
                  <p className="text-sm font-medium leading-none">
                    Nächste Ausgabe vorbereiten
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Fällig in 3 Tagen
                  </p>
                </div>
              </div>
              
              <div className="flex items-start gap-4">
                <div className="mt-0.5 h-5 w-5 rounded-full border-2 border-primary"></div>
                <div className="space-y-1">
                  <p className="text-sm font-medium leading-none">
                    Umfrageergebnisse auswerten
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Fällig in 7 Tagen
                  </p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
};

export default DashboardPage;
