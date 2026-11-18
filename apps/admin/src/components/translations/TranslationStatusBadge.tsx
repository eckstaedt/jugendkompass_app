import { Badge } from '@/components/ui/badge';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { Check, Clock, AlertTriangle, CircleSlash } from 'lucide-react';
import type { LangSummaryStatus } from '@/hooks/use-translations';

interface Props {
  lang: string;
  status: LangSummaryStatus;
}

const CONFIG: Record<LangSummaryStatus, {
  variant: 'success' | 'secondary' | 'warning' | 'destructive';
  icon: typeof Check;
  label: string;
}> = {
  ok:       { variant: 'success',     icon: Check,         label: 'Übersetzung vollständig' },
  partial:  { variant: 'warning',     icon: Clock,         label: 'Übersetzung unvollständig' },
  outdated: { variant: 'destructive', icon: AlertTriangle, label: 'Übersetzung veraltet' },
  missing:  { variant: 'secondary',   icon: CircleSlash,   label: 'Noch nicht übersetzt' },
};

export function TranslationStatusBadge({ lang, status }: Props) {
  const cfg = CONFIG[status];
  const Icon = cfg.icon;
  return (
    <TooltipProvider delayDuration={150}>
      <Tooltip>
        <TooltipTrigger asChild>
          <Badge variant={cfg.variant as any} className="gap-1 uppercase">
            <Icon className="h-3 w-3" />
            {lang}
          </Badge>
        </TooltipTrigger>
        <TooltipContent>{cfg.label} ({lang.toUpperCase()})</TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}

interface ListProps {
  /** Map language -> summary status. DE wird automatisch als Original "ok" angezeigt. */
  statuses: Record<string, LangSummaryStatus>;
  showDe?: boolean;
}

export function TranslationStatusList({ statuses, showDe = true }: ListProps) {
  return (
    <div className="flex flex-wrap items-center gap-1">
      {showDe && <TranslationStatusBadge lang="de" status="ok" />}
      {Object.entries(statuses).map(([lang, status]) => (
        <TranslationStatusBadge key={lang} lang={lang} status={status} />
      ))}
    </div>
  );
}
