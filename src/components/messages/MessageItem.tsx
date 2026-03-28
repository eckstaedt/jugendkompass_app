
import { useState } from 'react';
import { Card, CardContent, CardFooter, CardHeader } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { useAuth } from '@/contexts/AuthContext';
import { Message } from '@/hooks/use-messages';
import { formatDistanceToNow } from 'date-fns';
import { de } from 'date-fns/locale';
import MessageForm from './MessageForm';

interface MessageItemProps {
  message: Message;
  onUpdate: (data: { id: number; title?: string; message: string; imageFile?: File }) => Promise<void>;
  onDelete: (id: number) => Promise<void>;
}

const MessageItem = ({ message, onUpdate, onDelete }: MessageItemProps) => {
  const [isEditing, setIsEditing] = useState(false);
  const { user } = useAuth();
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
            className="mt-4 rounded-md max-w-sm"
          />
        )}
      </CardContent>
      {isOwner && (
        <CardFooter className="gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setIsEditing(true)}
          >
            Bearbeiten
          </Button>
          <Button
            variant="destructive"
            size="sm"
            onClick={() => onDelete(message.id)}
          >
            Löschen
          </Button>
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
