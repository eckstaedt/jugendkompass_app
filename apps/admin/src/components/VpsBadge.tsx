import { supabase } from '@/integrations/supabase/client';
import { cn } from '@/lib/utils';

// Backend of this admin build. Read from the actual client so the badge can
// never lie: a build that still talks to the old Supabase cloud shows nothing.
const backendUrl = (supabase as unknown as { supabaseUrl?: string }).supabaseUrl ?? '';

/** True when this admin writes to the self-hosted VPS (api.jugendkompass.com). */
export const isVpsBackend = backendUrl.includes('api.jugendkompass.com');

/** "NEW" badge shown next to the logo, only in the VPS admin. */
export const VpsBadge = ({ className }: { className?: string }) => {
  if (!isVpsBackend) return null;
  return (
    <span
      title="Dieser Admin-Bereich speichert alles auf dem eigenen Server (VPS)."
      className={cn(
        'inline-flex select-none items-center rounded-full bg-emerald-600 px-1.5 py-0.5 text-[10px] font-bold uppercase leading-none tracking-wide text-white',
        className,
      )}
    >
      New
    </span>
  );
};
