import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Languages, Loader2 } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { useQueryClient } from '@tanstack/react-query';

interface BackfillButtonProps {
  contentType: 'post' | 'impulse' | 'verse' | 'message' | 'poll' | 'video';
  label?: string;
  invalidateKeys?: string[];
}

export function BackfillButton({ contentType, label = 'Übersetzungen ergänzen', invalidateKeys = [] }: BackfillButtonProps) {
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState<{ done: number; failed: number } | null>(null);
  const { toast } = useToast();
  const qc = useQueryClient();

  const handleClick = async () => {
    setLoading(true);
    setProgress({ done: 0, failed: 0 });

    let totalDone = 0;
    let totalFailed = 0;
    const MAX_BATCHES = 50;

    try {
      for (let i = 0; i < MAX_BATCHES; i++) {
        const { data, error } = await supabase.functions.invoke('translate-backfill', {
          body: {
            target_languages: ['en', 'es', 'ru'],
            content_types: [contentType],
            force: false,
            only_missing: true,
            limit: 5,
            delay_ms: 150,
          },
        });
        if (error) throw error;

        const { processed = 0, success = 0, failed = 0, has_more = false, remaining = 0 } =
          (data as any) ?? {};
        totalDone += success;
        totalFailed += failed;
        setProgress({ done: totalDone, failed: totalFailed });

        if (processed === 0 || !has_more) {
          toast({
            title: 'Backfill abgeschlossen',
            description: `${totalDone} übersetzt${totalFailed ? `, ${totalFailed} fehlgeschlagen` : ''}${remaining ? `, ${remaining} verbleibend` : ''}.`,
          });
          break;
        }
      }

      invalidateKeys.forEach((k) => qc.invalidateQueries({ queryKey: [k] }));
      qc.invalidateQueries({ queryKey: ['content-translations'] });
    } catch (e) {
      console.error('Backfill error:', e);
      toast({
        title: 'Fehler',
        description: e instanceof Error ? e.message : 'Backfill fehlgeschlagen.',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
      setProgress(null);
    }
  };

  return (
    <Button variant="outline" onClick={handleClick} disabled={loading}>
      {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Languages className="mr-2 h-4 w-4" />}
      {loading
        ? progress
          ? `Übersetze... (${progress.done}${progress.failed ? ` / ${progress.failed} Fehler` : ''})`
          : 'Übersetze...'
        : label}
    </Button>
  );
}
