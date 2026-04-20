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
  const { toast } = useToast();
  const qc = useQueryClient();

  const handleClick = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase.functions.invoke('translate-backfill', {
        body: {
          target_languages: ['en'],
          content_types: [contentType],
          force: false,
          delay_ms: 200,
        },
      });
      if (error) throw error;

      const { total = 0, success = 0, failed = 0 } = (data as any) ?? {};
      toast({
        title: 'Backfill abgeschlossen',
        description: `${success}/${total} erfolgreich übersetzt${failed ? `, ${failed} fehlgeschlagen` : ''}.`,
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
    }
  };

  return (
    <Button variant="outline" onClick={handleClick} disabled={loading}>
      {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Languages className="mr-2 h-4 w-4" />}
      {loading ? 'Übersetze...' : label}
    </Button>
  );
}
