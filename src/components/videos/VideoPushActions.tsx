import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { BellIcon, SendIcon, LoaderCircle } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { useTestPushDevices, useSendTestPush } from '@/hooks/use-test-push-devices';
import { Video } from '@/lib/supabase';
import { format } from 'date-fns';
import { de } from 'date-fns/locale';

interface Props {
  video: Video & { notification_sent_at?: string | null };
  onSent?: () => void;
}

export default function VideoPushActions({ video, onSent }: Props) {
  const { toast } = useToast();
  const { data: devices } = useTestPushDevices();
  const sendTestPush = useSendTestPush();
  const [isTesting, setIsTesting] = useState(false);
  const [isDispatching, setIsDispatching] = useState(false);

  const sentAt = (video as any).notification_sent_at as string | null | undefined;

  const stripHtml = (html?: string | null) =>
    (html ?? '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();

  const handleTest = async () => {
    const ids = (devices ?? []).map((d: any) => d.id);
    if (ids.length === 0) {
      toast({ title: 'Keine Test-Geräte', description: 'Bitte zuerst Test-Geräte anlegen.', variant: 'destructive' });
      return;
    }
    setIsTesting(true);
    try {
      const res = await sendTestPush.mutateAsync({
        device_ids: ids,
        title: video.title || 'Neues Video',
        body: stripHtml(video.description) || video.title,
        image_url: video.image_url ?? null,
        data: {
          contentType: 'video',
          contentId: (video as any).content_id ?? '',
          entity_id: String(video.id),
        },
      });
      const ok = (res?.results ?? []).filter((r: any) => r.ok).length;
      toast({ title: 'Test-Push gesendet', description: `${ok} von ${ids.length} Geräten erreicht` });
    } catch (e: any) {
      toast({ title: 'Fehler', description: e?.message ?? 'Test-Push fehlgeschlagen', variant: 'destructive' });
    } finally {
      setIsTesting(false);
    }
  };

  const handleDispatch = async () => {
    const resend = !!sentAt;
    const ok = window.confirm(
      resend
        ? `Push für "${video.title}" ERNEUT an ALLE App-Nutzer senden?`
        : `Push für "${video.title}" jetzt an ALLE App-Nutzer senden? Dies kann nicht rückgängig gemacht werden.`
    );
    if (!ok) return;
    setIsDispatching(true);
    try {
      const { data, error } = await supabase.functions.invoke('dispatch-video-pushes', {
        body: { video_id: video.id, force: resend },
      });
      if (error) {
        const ctx = await (error as any)?.context?.json?.().catch(() => null);
        throw new Error(ctx?.error ?? error.message);
      }
      toast({
        title: 'Push gesendet',
        description: `${data?.sent ?? 0} von ${data?.total ?? 0} Geräten erreicht`,
      });
      onSent?.();
    } catch (e: any) {
      toast({ title: 'Fehler', description: e?.message ?? 'Push fehlgeschlagen', variant: 'destructive' });
    } finally {
      setIsDispatching(false);
    }
  };

  return (
    <div className="flex flex-wrap items-center gap-2 pt-1">
      <Button variant="outline" size="sm" onClick={handleTest} disabled={isTesting}>
        {isTesting ? <LoaderCircle className="h-4 w-4 animate-spin" /> : <BellIcon className="h-4 w-4" />}
        <span className="ml-1">Test-Push</span>
      </Button>
      <Button variant={sentAt ? 'outline' : 'default'} size="sm" onClick={handleDispatch} disabled={isDispatching}>
        {isDispatching ? <LoaderCircle className="h-4 w-4 animate-spin" /> : <SendIcon className="h-4 w-4" />}
        <span className="ml-1">{sentAt ? 'Erneut senden' : 'An alle senden'}</span>
      </Button>
      {sentAt && (
        <span className="text-xs text-muted-foreground">
          Gesendet: {format(new Date(sentAt), 'dd.MM.yyyy HH:mm', { locale: de })}
        </span>
      )}
    </div>
  );
}
