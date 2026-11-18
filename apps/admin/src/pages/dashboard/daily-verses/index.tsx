import { useState, useRef, useCallback, useEffect } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { VerseDialog } from '@/components/verses/VerseDialog';
import { VersesTable } from '@/components/verses/VersesTable';
import { useDailyVerses } from '@/hooks/use-daily-verses';
import { useAuth } from '@/contexts/AuthContext';
import { format, isToday, isFuture } from 'date-fns';
import { de } from 'date-fns/locale';
import { CalendarPlus, LayoutList, ViewIcon, Loader2, Download, Search, X, CalendarSearch } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';
import { DailyVerse } from '@/lib/supabase';
import { useTranslationsForContents, summarizeLang, SUPPORTED_LANGS } from '@/hooks/use-translations';
import { TranslationStatusList } from '@/components/translations/TranslationStatusBadge';

const DailyVersesPage = () => {
  const [searchInput, setSearchInput] = useState('');
  const [search, setSearch] = useState('');
  const [jumpDate, setJumpDate] = useState('');
  const { verses, isLoading, createVerse, updateVerse, fetchNextPage, hasNextPage, isFetchingNextPage } = useDailyVerses({ search, jumpDate: jumpDate || undefined });
  const isSearching = search.trim().length >= 2;

  // Suche erst nach kurzer Tipp-Pause starten
  useEffect(() => {
    const t = setTimeout(() => setSearch(searchInput), 300);
    return () => clearTimeout(t);
  }, [searchInput]);

  const jumpTo = (date: string) => {
    setSearchInput('');
    setSearch('');
    setJumpDate(date);
  };

  const resetFilters = () => {
    setSearchInput('');
    setSearch('');
    setJumpDate('');
  };

  // Nach dem Sprung den Vers des gewählten Tages in den Blick scrollen
  useEffect(() => {
    if (!jumpDate || isLoading) return;
    document.getElementById(`verse-${jumpDate}`)?.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }, [jumpDate, isLoading, verses.length]);
  const jumpTarget = jumpDate && !isSearching ? verses.find((v) => v.date === jumpDate) : undefined;
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

      <div className="mb-6 flex flex-wrap items-center gap-3">
        <div className="relative w-full sm:w-80">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            placeholder="Vers oder Bibelstelle suchen…"
            className="pl-9"
          />
        </div>
        <div className="flex items-center gap-2">
          <CalendarSearch className="h-4 w-4 text-muted-foreground" />
          <Input
            type="date"
            value={jumpDate}
            onChange={(e) => jumpTo(e.target.value)}
            className="w-[170px]"
            aria-label="Zu Datum springen"
          />
        </div>
        {(searchInput || jumpDate) && (
          <Button variant="ghost" size="sm" onClick={resetFilters}>
            <X className="mr-1 h-4 w-4" />
            Zurücksetzen
          </Button>
        )}
      </div>

      {isSearching && !isLoading && (
        <p className="mb-4 text-sm text-muted-foreground">
          {verses.length === 0
            ? `Keine Verse zu „${search.trim()}“ gefunden.`
            : `Treffer zu „${search.trim()}“${hasNextPage ? ' (weitere beim Scrollen)' : ''}:`}
        </p>
      )}
      {jumpDate && !isSearching && !isLoading && !jumpTarget && (
        <p className="mb-4 text-sm text-muted-foreground">
          Für den {format(new Date(jumpDate), 'dd.MM.yyyy')} ist kein Vers eingetragen – angezeigt werden die Tage davor.
        </p>
      )}

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
                  id={`verse-${verse.date}`}
                  className={cn(
                    "relative overflow-hidden transition-colors",
                    isCurrentOrFuture && "border-primary",
                    isToday(verseDate) && "bg-primary/5",
                    jumpTarget?.id === verse.id && "ring-2 ring-primary ring-offset-2"
                  )}
                >
                  {verse.image_url && (
                    <img
                      src={verse.image_url}
                      alt=""
                      className="w-full h-32 object-cover"
                    />
                  )}
                  <CardHeader>
                    <CardTitle className="flex items-center justify-between">
                      <span>{format(verseDate, "EEEE, dd. MMMM yyyy", { locale: de })}</span>
                    </CardTitle>
                    <CardDescription>{verse.reference}</CardDescription>
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
                    <div className="mt-4 flex flex-wrap gap-2">
                      {isAdmin && (
                        <Button
                          variant="outline"
                          onClick={() => handleEdit(verse)}
                        >
                          Bearbeiten
                        </Button>
                      )}
                      {isSearching && (
                        <Button variant="ghost" onClick={() => jumpTo(verse.date)}>
                          <CalendarSearch className="mr-2 h-4 w-4" />
                          Zum Datum
                        </Button>
                      )}
                    </div>
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
