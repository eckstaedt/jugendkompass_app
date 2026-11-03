import { useState, useRef, useCallback } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { VerseDialog } from '@/components/verses/VerseDialog';
import { VersesTable } from '@/components/verses/VersesTable';
import { useDailyVerses, VerseListMode } from '@/hooks/use-daily-verses';
import { VerseScheduleOverview } from '@/components/verses/VerseScheduleOverview';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { useAuth } from '@/contexts/AuthContext';
import { format, isToday, isFuture } from 'date-fns';
import { de } from 'date-fns/locale';
import { CalendarPlus, LayoutList, ViewIcon, Loader2, Download, Sparkles, ImageIcon } from 'lucide-react';
import { cn } from '@/lib/utils';
import { DailyVerse } from '@/lib/supabase';
import { useTranslationsForContents, summarizeLang, SUPPORTED_LANGS } from '@/hooks/use-translations';
import { TranslationStatusList } from '@/components/translations/TranslationStatusBadge';

const DailyVersesPage = () => {
  const [listMode, setListMode] = useState<VerseListMode>('upcoming');
  const [fromDate, setFromDate] = useState<string | undefined>();
  const { verses, isLoading, createVerse, updateVerse, fetchNextPage, hasNextPage, isFetchingNextPage } = useDailyVerses(listMode, fromDate);

  const jumpTo = (isoDate: string | undefined) => {
    setListMode('upcoming');
    setFromDate(isoDate);
  };
  const { data: translationsMap } = useTranslationsForContents((verses ?? []).map((v: any) => v.content_id));
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedVerse, setSelectedVerse] = useState<DailyVerse | undefined>();
  const [viewMode, setViewMode] = useState<'cards' | 'table'>('cards');
  const { isAdmin, user } = useAuth();

  const observerRef = useRef<IntersectionObserver | null>(null);
  const loadMoreRef = useCallback((node: HTMLDivElement | null) => {
    if (isFetchingNextPage) return;
    if (observerRef.current) observerRef.current.disconnect();
    observerRef.current = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting && hasNextPage) {
        fetchNextPage();
      }
    });
    if (node) observerRef.current.observe(node);
  }, [isFetchingNextPage, hasNextPage, fetchNextPage]);

  const handleEdit = (verse: DailyVerse) => {
    setSelectedVerse(verse);
    setDialogOpen(true);
  };

  const handleCreate = () => {
    setSelectedVerse(undefined);
    setDialogOpen(true);
  };

  const handleDialogSubmit = async (data: Omit<DailyVerse, 'id' | 'content_id' | 'created_at' | 'content'>) => {
    try {
      if (selectedVerse) {
        await updateVerse.mutateAsync({
          ...data,
          id: selectedVerse.id,
          content_id: selectedVerse.content_id,
        });
      } else if (user?.id) {
        await createVerse.mutateAsync({
          ...data,
          userId: user.id,
        });
      }
      setDialogOpen(false);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'Speichern fehlgeschlagen');
    }
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
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="icon"
            onClick={() => setViewMode(viewMode === 'cards' ? 'table' : 'cards')}
          >
            {viewMode === 'cards' ? (
              <LayoutList className="h-4 w-4" />
            ) : (
              <ViewIcon className="h-4 w-4" />
            )}
            <span className="sr-only">
              Ansicht wechseln zu {viewMode === 'cards' ? 'Tabelle' : 'Karten'}
            </span>
          </Button>
          {isAdmin && (
            <Button onClick={handleCreate}>
              <CalendarPlus className="mr-2 h-4 w-4" />
              Neuer Vers des Tages
            </Button>
          )}
        </div>
      </div>

      <VerseScheduleOverview onSelectYear={(year) => jumpTo(year === new Date().getFullYear() ? undefined : `${year}-01-01`)} />

      <div className="mb-4 flex flex-wrap items-center gap-3">
        <Tabs value={listMode} onValueChange={(v) => setListMode(v as VerseListMode)}>
          <TabsList>
            <TabsTrigger value="upcoming">Kommende</TabsTrigger>
            <TabsTrigger value="past">Vergangene</TabsTrigger>
          </TabsList>
        </Tabs>
        {listMode === 'upcoming' && (
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <span>ab</span>
            <Input
              type="month"
              className="w-[170px]"
              value={(fromDate ?? format(new Date(), 'yyyy-MM-dd')).slice(0, 7)}
              onChange={(e) => jumpTo(e.target.value ? `${e.target.value}-01` : undefined)}
            />
            {fromDate && (
              <Button variant="ghost" size="sm" onClick={() => jumpTo(undefined)}>
                Heute
              </Button>
            )}
          </div>
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
      ) : viewMode === 'cards' ? (
        <>
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
                  {verse.image_url ? (
                    <img
                      src={verse.image_url}
                      alt=""
                      loading="lazy"
                      className="w-full aspect-square object-cover"
                    />
                  ) : (
                    <div className="flex h-32 w-full items-center justify-center gap-2 bg-muted text-xs text-muted-foreground">
                      <ImageIcon className="h-4 w-4" />
                      Naturbild wird automatisch erzeugt
                    </div>
                  )}
                  <CardHeader>
                    <CardTitle className="flex items-center justify-between">
                      <span>{format(verseDate, "EEEE, dd. MMMM yyyy", { locale: de })}</span>
                    </CardTitle>
                    <CardDescription className="flex flex-wrap items-center gap-2">
                      <span>{verse.reference}</span>
                      {verse.auto_scheduled && (
                        <Badge variant="secondary" className="font-normal">
                          <Sparkles className="mr-1 h-3 w-3" />
                          automatisch geplant
                        </Badge>
                      )}
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <p className="text-pretty">{verse.verse}</p>
                    <div className="mt-3">
                      <TranslationStatusList
                        statuses={Object.fromEntries(
                          SUPPORTED_LANGS.map((l) => [
                            l,
                            summarizeLang(translationsMap?.[verse.content_id], l, ['verse', 'reference']),
                          ])
                        )}
                      />
                    </div>
                    {(verse.usage_count ?? 0) > 0 && (
                      <div className="mt-2 flex items-center gap-1 text-xs text-muted-foreground">
                        <Download className="h-3 w-3" />
                        <span>{verse.usage_count} Teilen/Downloads</span>
                      </div>
                    )}
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
              );
            })}
          </div>
          <div ref={loadMoreRef} className="flex justify-center py-6">
            {isFetchingNextPage && (
              <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
            )}
          </div>
        </>
      ) : (
        <VersesTable verses={verses} onEdit={handleEdit} />
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
