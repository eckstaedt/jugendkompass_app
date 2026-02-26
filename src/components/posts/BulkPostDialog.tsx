import { useState } from 'react';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogDescription,
} from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';
import { LoaderCircle, Upload } from 'lucide-react';

type BulkPostEntry = {
  title: string;
  body: string;
  image_url?: string | null;
  audio_id?: string | null;
  category_id: string;
  edition_id: string;
};

type BulkPostDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (posts: BulkPostEntry[]) => Promise<void>;
};

export function BulkPostDialog({ open, onOpenChange, onSubmit }: BulkPostDialogProps) {
  const [jsonInput, setJsonInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const { toast } = useToast();

  const handleSubmit = async () => {
    try {
      const parsed = JSON.parse(jsonInput);
      const entries: BulkPostEntry[] = Array.isArray(parsed) ? parsed : [parsed];

      for (const entry of entries) {
        if (!entry.title || !entry.body || !entry.category_id || !entry.edition_id) {
          toast({
            title: 'Validierungsfehler',
            description: 'Jeder Eintrag muss title, body, category_id und edition_id enthalten.',
            variant: 'destructive',
          });
          return;
        }
      }

      setIsLoading(true);
      await onSubmit(entries);
      toast({
        title: 'Erfolg',
        description: `${entries.length} Beitrag/Beiträge erfolgreich importiert.`,
      });
      setJsonInput('');
      onOpenChange(false);
    } catch (e) {
      if (e instanceof SyntaxError) {
        toast({
          title: 'JSON-Fehler',
          description: 'Ungültiges JSON-Format. Bitte überprüfe die Eingabe.',
          variant: 'destructive',
        });
      } else {
        toast({
          title: 'Fehler',
          description: 'Fehler beim Importieren der Beiträge.',
          variant: 'destructive',
        });
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>Beiträge JSON Import</DialogTitle>
          <DialogDescription>
            Füge ein JSON-Array mit Beiträgen ein. Jeder Eintrag benötigt: title, body, category_id, edition_id und optional image_url.
          </DialogDescription>
        </DialogHeader>
        <Textarea
          value={jsonInput}
          onChange={(e) => setJsonInput(e.target.value)}
          placeholder={`[{\n  "title": "Titel",\n  "body": "<p>Text...</p>",\n  "image_url": "https://...",\n  "audio_id": "uuid (optional)",\n  "category_id": "uuid",\n  "edition_id": "uuid"\n}]`}
          className="min-h-[250px] font-mono text-sm"
        />
        <DialogFooter>
          <Button onClick={handleSubmit} disabled={isLoading || !jsonInput.trim()}>
            {isLoading ? (
              <>
                <LoaderCircle className="mr-2 h-4 w-4 animate-spin" />
                Importiere...
              </>
            ) : (
              <>
                <Upload className="mr-2 h-4 w-4" />
                Importieren
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
