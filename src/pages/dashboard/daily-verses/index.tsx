
import { useState } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { VerseDialog } from '@/components/verses/VerseDialog';
import { useDailyVerses, DailyVerse } from '@/hooks/use-daily-verses';
import { useAuth } from '@/contexts/AuthContext';
import { format, isToday, isFuture } from 'date-fns';
import { de } from 'date-fns/locale';
import { CalendarPlus } from 'lucide-react';

const DailyVersesPage = () => {
  const { verses, isLoading, createVerse, updateVerse } = useDailyVerses();
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedVerse, setSelectedVerse] = useState<DailyVerse | undefined>();
  const { isAdmin } = useAuth();
  
  const handleEdit = (verse: DailyVerse) => {
    setSelectedVerse(verse);
    setDialogOpen(true);
  };
  
  const handleCreate = () => {
    setSelectedVerse(undefined);
    setDialogOpen(true);
  };
  
  const handleDialogSubmit = async (data: Omit<DailyVerse, 'id'>) => {
    if (selectedVerse) {
      await updateVerse.mutateAsync({ ...data, id: selectedVerse.id });
    } else {
      await createVerse.mutateAsync(data);
    }
    setDialogOpen(false);
  };

  return (
    <DashboardLayout title="Vers des Tages">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Vers des Tages verwalten</h2>
          <p className="text-muted-foreground">
            Verwalte die täglichen Bibelverse für die App.
          </p>
        </div>
        {isAdmin && (
          <Button onClick={handleCreate}>
            <CalendarPlus className="mr-2 h-4 w-4" />
            Neuer Tagesvers
          </Button>
        )}
      </div>

      {isLoading ? (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3].map((i) => (
            <Card key={i} className="animate-pulse">
              <CardHeader className="h-24 bg-muted" />
              <CardContent className="h-32 bg-muted mt-4" />
            </Card>
          ))}
        </div>
      ) : (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {verses.map((verse) => {
            const verseDate = new Date(verse.date);
            const isCurrentOrFuture = isToday(verseDate) || isFuture(verseDate);
            
            return (
              <Card 
                key={verse.id}
                className={cn(
                  "relative overflow-hidden transition-colors",
                  isCurrentOrFuture && "border-primary",
                  isToday(verseDate) && "bg-primary/5"
                )}
              >
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span>{format(verseDate, "EEEE, dd. MMMM yyyy", { locale: de })}</span>
                  </CardTitle>
                  <CardDescription>{verse.reference}</CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-pretty">{verse.verse}</p>
                  {isAdmin && (
                    <Button
                      variant="outline"
                      className="mt-4"
                      onClick={() => handleEdit(verse)}
                    >
                      Bearbeiten
                    </Button>
                  )}
                </CardContent>
              </Card>
            )
          })}
        </div>
      )}

      <VerseDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        onSubmit={handleDialogSubmit}
        initialData={selectedVerse}
        mode={selectedVerse ? 'edit' : 'create'}
      />
    </DashboardLayout>
  );
};

export default DailyVersesPage;
