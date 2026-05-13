import React, { useState, useEffect } from 'react';
import { format } from 'date-fns';
import { CalendarIcon, LoaderCircle } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useUpdateVideo } from '@/hooks/use-videos';
import { useToast } from '@/hooks/use-toast';
import { Video } from '@/lib/supabase';
import RichTextEditor from '@/components/editor/RichTextEditor';
import { ImageUploader } from '@/components/posts/ImageUploader';
import { RetranslateButton } from '@/components/translations/RetranslateButton';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { cn } from '@/lib/utils';

type EditVideoDialogProps = {
  video: Video | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
};

const EditVideoDialog = ({ video, open, onOpenChange }: EditVideoDialogProps) => {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [url, setUrl] = useState('');
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [createdAt, setCreatedAt] = useState<Date | undefined>(undefined);
  const updateVideoMutation = useUpdateVideo();
  const { toast } = useToast();

  useEffect(() => {
    if (video) {
      setTitle(video.title);
      setDescription(video.description || '');
      setUrl(video.url);
      setImageUrl(video.image_url || null);
      setCreatedAt(video.created_at ? new Date(video.created_at) : undefined);
    }
  }, [video]);

  const handleSave = async () => {
    if (!video || !title || !imageUrl) return;

    try {
      await updateVideoMutation.mutateAsync({
        id: video.id,
        title,
        description,
        url,
        imageUrl: imageUrl!,
        createdAt: createdAt ? createdAt.toISOString() : undefined,
      });

      toast({
        title: 'Video aktualisiert',
        description: 'Das Video wurde erfolgreich gespeichert.',
      });
      onOpenChange(false);
    } catch (error) {
      toast({
        title: 'Fehler',
        description: 'Das Video konnte nicht aktualisiert werden.',
        variant: 'destructive',
      });
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Video bearbeiten</DialogTitle>
        </DialogHeader>
        <div className="space-y-4 py-4">
          <div>
            <label className="block text-sm font-medium mb-1">Titel</label>
            <Input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Video-Titel"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Beschreibung</label>
            <RichTextEditor content={description} onChange={setDescription} />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">URL</label>
            <Input
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              placeholder="Video-URL"
            />
          </div>
          <ImageUploader
            value={imageUrl}
            onChange={setImageUrl}
            required
            label="Thumbnail (JPEG, PNG, max. 3MB)*"
          />
        </div>
        <DialogFooter className="gap-2 sm:justify-between">
          {video?.content_id && <RetranslateButton contentId={video.content_id} />}
          <div className="flex gap-2">
            <Button variant="outline" onClick={() => onOpenChange(false)}>
              Abbrechen
            </Button>
            <Button
              onClick={handleSave}
              disabled={!title || !imageUrl || updateVideoMutation.isPending}
            >
              {updateVideoMutation.isPending ? (
                <>
                  <LoaderCircle className="mr-2 h-4 w-4 animate-spin" />
                  Speichern...
                </>
              ) : (
                'Speichern'
              )}
            </Button>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default EditVideoDialog;
