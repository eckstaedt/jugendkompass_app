import { useQuery } from '@tanstack/react-query';
import { format } from 'date-fns';
import { de } from 'date-fns/locale';
import { AlertTriangle, CalendarCheck2, ImageIcon } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';

type YearRow = {
  year: number;
  days_in_year: number;
  days_planned: number;
  auto_planned: number;
  with_image: number;
  conflicts: number;
  first_free_day: string | null;
};

const useVerseScheduleOverview = () =>
  useQuery({
    queryKey: ['verseScheduleOverview'],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('get_verse_schedule_overview');
      if (error) throw error;
      return (data ?? []) as YearRow[];
    },
  });

const useUpcomingConflicts = (enabled: boolean) =>
  useQuery({
    queryKey: ['verseScheduleOverview', 'conflicts'],
    enabled,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('verse_schedule_conflicts')
        .select('first_date, second_date, reference, days_between')
        .gte('second_date', format(new Date(), 'yyyy-MM-dd'))
        .order('second_date')
        .limit(30);
      if (error) throw error;
      return (data ?? []) as { first_date: string; second_date: string; reference: string; days_between: number }[];
    },
  });

interface Props {
  /** Jump the list to 1 January of the clicked year */
  onSelectYear?: (year: number) => void;
}

export const VerseScheduleOverview = ({ onSelectYear }: Props) => {
  const { data: years, isLoading, error } = useVerseScheduleOverview();
  const hasConflicts = (years ?? []).some((y) => y.conflicts > 0);
  const { data: conflicts } = useUpcomingConflicts(hasConflicts);
  const fmt = (d: string) => format(new Date(d), 'dd.MM.yyyy', { locale: de });

  if (isLoading) {
    return <Card className="mb-6 h-40 animate-pulse bg-muted" />;
  }
  if (error || !years?.length) {
    return null;
  }

  const currentYear = new Date().getFullYear();
  // fully planned from today onwards up to (and including) this year
  let plannedUntil: number | null = null;
  for (const y of years) {
    if (y.first_free_day) break;
    plannedUntil = y.year;
  }
  const totalConflicts = (years ?? []).reduce((s, y) => s + y.conflicts, 0);
  const firstGap = years.find((y) => y.first_free_day)?.first_free_day;

  return (
    <Card className="mb-6">
      <CardHeader className="pb-3">
        <CardTitle className="flex flex-wrap items-center gap-2 text-lg">
          <CalendarCheck2 className="h-5 w-5 text-primary" />
          {plannedUntil && plannedUntil > currentYear
            ? `Verse sind bis Ende ${plannedUntil} geplant`
            : 'Planung der Verse'}
          {totalConflicts === 0 ? (
            <Badge variant="secondary">keine Doppelungen</Badge>
          ) : (
            <Badge variant="destructive">
              <AlertTriangle className="mr-1 h-3 w-3" />
              {totalConflicts} Doppelung{totalConflicts === 1 ? '' : 'en'}
            </Badge>
          )}
        </CardTitle>
        <CardDescription>
          Wird automatisch jede Nacht fortgeschrieben (immer 10 Jahre im Voraus). Jeder Vers höchstens
          einmal pro Jahr und mit mindestens 365 Tagen Abstand. Bilder werden automatisch ca. 45 Tage
          vorher erzeugt.
          {firstGap && (
            <> Erster freier Tag: <strong>{format(new Date(firstGap), 'dd.MM.yyyy', { locale: de })}</strong>.</>
          )}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {years.map((y) => {
            const pct = Math.round((y.days_planned / y.days_in_year) * 100);
            const complete = !y.first_free_day;
            return (
              <button
                key={y.year}
                type="button"
                onClick={() => onSelectYear?.(y.year)}
                className={cn(
                  'rounded-md border p-3 text-left transition-colors hover:bg-muted/60',
                  y.conflicts > 0 && 'border-destructive',
                )}
              >
                <div className="flex items-center justify-between">
                  <span className="font-semibold">{y.year}</span>
                  <span className={cn('text-xs', complete ? 'text-primary' : 'text-muted-foreground')}>
                    {complete ? 'vollständig ✓' : `${y.days_planned}/${y.days_in_year} Tage`}
                  </span>
                </div>
                <Progress value={pct} className="mt-2 h-1.5" />
                <div className="mt-2 flex items-center gap-3 text-xs text-muted-foreground">
                  <span className="flex items-center gap-1">
                    <ImageIcon className="h-3 w-3" />
                    {y.with_image} Bilder
                  </span>
                  {y.conflicts > 0 && (
                    <span className="flex items-center gap-1 text-destructive">
                      <AlertTriangle className="h-3 w-3" />
                      {y.conflicts}
                    </span>
                  )}
                </div>
              </button>
            );
          })}
        </div>
        {!!conflicts?.length && (
          <div className="mt-4 rounded-md border border-destructive/50 p-3 text-sm">
            <p className="mb-2 font-medium text-destructive">
              Diese Tage verletzen die Regel (gleicher Vers im selben Jahr oder &lt; 365 Tage Abstand):
            </p>
            <ul className="space-y-1 text-muted-foreground">
              {conflicts.map((c) => (
                <li key={`${c.first_date}-${c.second_date}`}>
                  {fmt(c.second_date)} – {c.reference} (schon am {fmt(c.first_date)}, {c.days_between} Tage vorher)
                </li>
              ))}
            </ul>
          </div>
        )}
      </CardContent>
    </Card>
  );
};
