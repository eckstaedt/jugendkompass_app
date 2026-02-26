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

type BulkImpulseEntry = {
  title: string;
  impulse_text: string;
  image_url: string;
  date: string;
};

type BulkImpulseDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (impulses: BulkImpulseEntry[]) => Promise<void>;
};

export function BulkImpulseDialog({ open, onOpenChange, onSubmit }: BulkImpulseDialogProps) {
  const [jsonInput, setJsonInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const { toast } = useToast();

  const handleSubmit = async () => {
    try {
      const parsed = JSON.parse(jsonInput);
      const entries: BulkImpulseEntry[] = Array.isArray(parsed) ? parsed : [parsed];

      for (const entry of entries) {
        if (!entry.impulse_text || !entry.date || !entry.title) {
          toast({
            title: 'Validierungsfehler',
            description: 'Jeder Eintrag muss title, impulse_text und date enthalten.',
            variant: 'destructive',
          });
          return;
        }
        if (!/^\d{4}-\d{2}-\d{2}$/.test(entry.date)) {
          toast({
            title: 'Validierungsfehler',
            description: `Ungültiges Datumsformat: ${entry.date}. Erwartet: YYYY-MM-DD`,
            variant: 'destructive',
          });
          return;
        }
      }

      setIsLoading(true);
      await onSubmit(entries);
      toast({
        title: 'Erfolg',
        description: `${entries.length} Impuls(e) erfolgreich importiert.`,
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
          description: 'Fehler beim Importieren der Impulse.',
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
          <DialogTitle>Impulse JSON Import</DialogTitle>
          <DialogDescription>
            Füge ein JSON-Array mit Impulsen ein. Jeder Eintrag benötigt: title, impulse_text, date und optional image_url.
          </DialogDescription>
        </DialogHeader>
        <Textarea
          value={jsonInput}
          onChange={(e) => setJsonInput(e.target.value)}
          placeholder={`[{\n  "title": "Titel",\n  "impulse_text": "<p>Text...</p>",\n  "image_url": "https://...",\n  "date": "2026-01-01"\n}]`}
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
