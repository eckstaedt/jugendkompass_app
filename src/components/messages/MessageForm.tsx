
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';
import RichTextEditor from '@/components/editor/RichTextEditor';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';

interface MessageFormProps {
  initialTitle?: string;
  initialMessage?: string;
  initialImageUrl?: string | null;
  onSubmit: (data: { title?: string; message: string; imageFile?: File }) => Promise<void>;
  isSubmitting: boolean;
}

const MessageForm = ({ initialTitle = '', initialMessage = '', initialImageUrl, onSubmit, isSubmitting }: MessageFormProps) => {
  const [title, setTitle] = useState(initialTitle);
  const [message, setMessage] = useState(initialMessage);
  const [imageFile, setImageFile] = useState<File | undefined>();
  const { toast } = useToast();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await onSubmit({ title: title || undefined, message, imageFile });
      setTitle('');
      setMessage('');
      setImageFile(undefined);
    } catch (error) {
      toast({
        title: "Fehler",
        description: "Beim Speichern der Nachricht ist ein Fehler aufgetreten.",
        variant: "destructive",
      });
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="title">Titel (optional)</Label>
        <Input
          id="title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Titel der Nachricht"
        />
      </div>

      <div className="space-y-2">
        <Label>Nachricht</Label>
        <RichTextEditor content={message} onChange={setMessage} />
      </div>

      <div className="space-y-2">
        <Label htmlFor="image">Bild (optional)</Label>
        <Input
          id="image"
          type="file"
          accept="image/*"
          onChange={(e) => setImageFile(e.target.files?.[0])}
        />
        {initialImageUrl && (
          <img 
            src={initialImageUrl} 
            alt="Current message image" 
            className="mt-2 max-w-sm rounded-md"
          />
        )}
      </div>

      <Button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Wird gespeichert...' : 'Speichern'}
      </Button>
    </form>
  );
};

export default MessageForm;
