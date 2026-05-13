
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
import { Message } from '@/hooks/use-messages';
import { formatDistanceToNow } from 'date-fns';
import { de } from 'date-fns/locale';
import MessageForm from './MessageForm';
import { useTranslationsForContents, summarizeLang, SUPPORTED_LANGS } from '@/hooks/use-translations';
import { TranslationStatusList } from '@/components/translations/TranslationStatusBadge';
import { RetranslateButton } from '@/components/translations/RetranslateButton';

interface MessageItemProps {
  message: Message;
  onUpdate: (data: { id: number; title: string; message: string; imageFile?: File }) => Promise<void>;
  onDelete: (id: number) => Promise<void>;
}

const MessageItem = ({ message, onUpdate, onDelete }: MessageItemProps) => {
  const [isEditing, setIsEditing] = useState(false);
  const { user } = useAuth();
  const { data: translationsMap } = useTranslationsForContents([message.content_id]);

  return (
    <Card>
      <CardHeader>
        {message.title && (
          <h3 className="font-semibold text-lg">{message.title}</h3>
        )}
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
        <DialogContent>
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
