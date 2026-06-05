
import { useState } from 'react';
import { Card, CardContent, CardFooter, CardHeader } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog';
import { useAuth } from '@/contexts/AuthContext';
import { Message, useSendMessagePush } from '@/hooks/use-messages';
import { formatDistanceToNow, format } from 'date-fns';
import { de } from 'date-fns/locale';
import MessageForm from './MessageForm';
import { useTranslationsForContents, summarizeLang, SUPPORTED_LANGS } from '@/hooks/use-translations';
import { TranslationStatusList } from '@/components/translations/TranslationStatusBadge';
import { RetranslateButton } from '@/components/translations/RetranslateButton';
import { useToast } from '@/hooks/use-toast';
import { Send, FlaskConical } from 'lucide-react';
import { useTestPushDevices, useSendTestPush } from '@/hooks/use-test-push-devices';

interface MessageItemProps {
  message: Message;
  onUpdate: (data: { id: number; title: string; message: string; imageFile?: File }) => Promise<void>;
  onDelete: (id: number) => Promise<void>;
}

const MessageItem = ({ message, onUpdate, onDelete }: MessageItemProps) => {
  const [isEditing, setIsEditing] = useState(false);
  const { user } = useAuth();
  const { data: translationsMap } = useTranslationsForContents([message.content_id]);
  const sendPush = useSendMessagePush();
  const { toast } = useToast();

  const handleSend = async (force: boolean) => {
    try {
      const res = await sendPush.mutateAsync({ id: message.id, force });
      toast({
        title: 'Push gesendet',
        description: `${res.sent} von ${res.total} Geräten erreicht.`,
      });
    } catch (e: any) {
      toast({
        title: 'Fehler beim Senden',
        description: e?.message ?? 'Unbekannter Fehler',
        variant: 'destructive',
      });
    }
  };

  const sentAt = message.notification_sent_at
    ? format(new Date(message.notification_sent_at), "dd.MM.yyyy HH:mm", { locale: de })
    : null;


  return (
    <Card>
      <CardHeader>
        <h3 className="font-semibold text-lg">{message.title}</h3>
        <div className="text-sm text-muted-foreground">
          {formatDistanceToNow(new Date(message.created_at), { addSuffix: true, locale: de })}
        </div>
      </CardHeader>
      <CardContent>
        <div 
          className="prose prose-sm max-w-none"
          dangerouslySetInnerHTML={{ __html: message.message }}
        />
        {message.image_url && (
          <img 
            src={message.image_url} 
            alt="" 
            className="mt-4 rounded-md max-w-[200px] max-h-[200px] object-cover"
          />
        )}
        {message.content_id && (
          <div className="mt-3">
            <TranslationStatusList
              statuses={Object.fromEntries(
                SUPPORTED_LANGS.map((l) => [
                  l,
                  summarizeLang(translationsMap?.[message.content_id!], l, ['title', 'message']),
                ])
              )}
            />
          </div>
        )}
      </CardContent>
      {user && (
        <CardFooter className="gap-2 flex-wrap">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setIsEditing(true)}
          >
            Bearbeiten
          </Button>
          {message.content_id && <RetranslateButton contentId={message.content_id} />}
          {sentAt ? (
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button variant="outline" size="sm" disabled={sendPush.isPending}>
                  <Send className="h-4 w-4 mr-1" />
                  Erneut senden
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Push erneut senden?</AlertDialogTitle>
                  <AlertDialogDescription>
                    Diese Nachricht wurde bereits am {sentAt} gesendet. Soll die Push-Benachrichtigung erneut an alle Geräte gesendet werden?
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>Abbrechen</AlertDialogCancel>
                  <AlertDialogAction onClick={() => handleSend(true)}>Erneut senden</AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          ) : (
            <Button
              variant="default"
              size="sm"
              onClick={() => handleSend(false)}
              disabled={sendPush.isPending}
            >
              <Send className="h-4 w-4 mr-1" />
              {sendPush.isPending ? 'Sende…' : 'Push senden'}
            </Button>
          )}
          <span className="text-xs text-muted-foreground">
            {sentAt ? `Gesendet: ${sentAt}` : 'Noch nicht gesendet'}
          </span>
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button variant="destructive" size="sm">
                Löschen
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Nachricht löschen?</AlertDialogTitle>
                <AlertDialogDescription>
                  Diese Aktion kann nicht rückgängig gemacht werden. Die Nachricht wird dauerhaft gelöscht.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Abbrechen</AlertDialogCancel>
                <AlertDialogAction onClick={() => onDelete(message.id)}>
                  Löschen
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        </CardFooter>
      )}

      <Dialog open={isEditing} onOpenChange={setIsEditing}>
        <DialogContent className="max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Nachricht bearbeiten</DialogTitle>
          </DialogHeader>
          <MessageForm
            initialTitle={message.title || ''}
            initialMessage={message.message}
            initialImageUrl={message.image_url}
            onSubmit={async (data) => {
              await onUpdate({ id: message.id, ...data });
              setIsEditing(false);
            }}
            isSubmitting={false}
          />
        </DialogContent>
      </Dialog>
    </Card>
  );
};

export default MessageItem;
