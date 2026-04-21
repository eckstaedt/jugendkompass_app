import { useState, useRef } from 'react';
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

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL as string;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string;

export function BackfillButton({ contentType, label = 'Übersetzungen ergänzen', invalidateKeys = [] }: BackfillButtonProps) {
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState<{ done: number; failed: number; remaining: number | null }>({
    done: 0,
    failed: 0,
    remaining: null,
  });
  const cancelRef = useRef(false);
  const { toast } = useToast();
  const qc = useQueryClient();

  const handleClick = async () => {
    if (loading) {
      cancelRef.current = true;
      return;
    }
    setLoading(true);
    cancelRef.current = false;
    setProgress({ done: 0, failed: 0, remaining: null });

    let totalDone = 0;
    let totalFailed = 0;
    let lastRemaining: number | null = null;
    const MAX_BATCHES = 500;

    try {
      const { data: sessionData } = await supabase.auth.getSession();
      const accessToken = sessionData.session?.access_token ?? SUPABASE_ANON_KEY;

      for (let i = 0; i < MAX_BATCHES; i++) {
        if (cancelRef.current) break;

        // Direkter fetch — umgeht supabase-js Timeouts und liefert volle Kontrolle
        const resp = await fetch(`${SUPABASE_URL}/functions/v1/translate-backfill`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            apikey: SUPABASE_ANON_KEY,
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            target_languages: ['en', 'es', 'ru', 'pl'],
            content_types: [contentType],
            force: false,
            only_missing: true,
            limit: 1, // 1 Inhalt pro Batch → ~25s Antwortzeit
            delay_ms: 0,
          }),
        });

        if (!resp.ok) {
          const txt = await resp.text();
          throw new Error(`HTTP ${resp.status}: ${txt}`);
        }
        const data = await resp.json();

        const { processed = 0, success = 0, failed = 0, has_more = false, remaining = 0 } = data ?? {};
        totalDone += success;
        totalFailed += failed;
        lastRemaining = remaining;
        setProgress({ done: totalDone, failed: totalFailed, remaining });

        // Invalidate während dem Lauf, damit User Updates live sehen
        if (i % 5 === 4) {
          invalidateKeys.forEach((k) => qc.invalidateQueries({ queryKey: [k] }));
          qc.invalidateQueries({ queryKey: ['content-translations'] });
        }

        if (processed === 0 || !has_more) {
          break;
        }
      }

      toast({
        title: cancelRef.current ? 'Backfill abgebrochen' : 'Backfill abgeschlossen',
        description: `${totalDone} übersetzt${totalFailed ? `, ${totalFailed} fehlgeschlagen` : ''}${lastRemaining ? `, ${lastRemaining} verbleibend` : ''}.`,
      });

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
      cancelRef.current = false;
    }
  };

  return (
    <Button variant={loading ? 'destructive' : 'outline'} onClick={handleClick}>
      {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Languages className="mr-2 h-4 w-4" />}
      {loading
        ? `Übersetze... ${progress.done}${progress.failed ? ` (${progress.failed} Fehler)` : ''}${progress.remaining !== null ? ` · noch ${progress.remaining}` : ''} — Stop`
        : label}
    </Button>
  );
}
