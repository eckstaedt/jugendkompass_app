import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";

interface BulkVerseDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (verses: { verse: string; reference: string; date: string }[]) => Promise<void>;
}

const EXAMPLE_JSON = `[{
  "verse": "O Herr, du bist mein Gott...",
  "date": "2026-02-26",
  "reference": "Jesaja 25:1"
}]`;

export function BulkVerseDialog({ open, onOpenChange, onSubmit }: BulkVerseDialogProps) {
  const [jsonInput, setJsonInput] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [parseError, setParseError] = useState<string | null>(null);

  const handleSubmit = async () => {
    setParseError(null);
    let parsed: unknown;
    try {
      parsed = JSON.parse(jsonInput);
    } catch {
      setParseError("Ungültiges JSON-Format.");
      return;
    }

    if (!Array.isArray(parsed) || parsed.length === 0) {
      setParseError("Das JSON muss ein nicht-leeres Array sein.");
      return;
    }

    for (let i = 0; i < parsed.length; i++) {
      const item = parsed[i];
      if (!item.verse || !item.reference || !item.date) {
        setParseError(`Eintrag ${i + 1}: verse, reference und date sind Pflichtfelder.`);
        return;
      }
      if (!/^\d{4}-\d{2}-\d{2}$/.test(item.date)) {
        setParseError(`Eintrag ${i + 1}: Datum muss im Format YYYY-MM-DD sein.`);
        return;
      }
    }

    setIsSubmitting(true);
    try {
      await onSubmit(parsed as { verse: string; reference: string; date: string }[]);
      toast.success(`${parsed.length} Verse erfolgreich importiert.`);
      setJsonInput("");
      onOpenChange(false);
    } catch (err: any) {
      toast.error("Fehler beim Import: " + (err?.message || "Unbekannter Fehler"));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[550px]">
        <DialogHeader>
          <DialogTitle>Verse importieren (JSON)</DialogTitle>
          <DialogDescription>
            Füge ein JSON-Array mit Versen ein. Jeder Eintrag benötigt <code>verse</code>, <code>reference</code> und <code>date</code>.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-3">
          <Label htmlFor="json-input">JSON-Daten</Label>
          <Textarea
            id="json-input"
            rows={10}
            className="font-mono text-sm"
            placeholder={EXAMPLE_JSON}
            value={jsonInput}
            onChange={(e) => {
              setJsonInput(e.target.value);
              setParseError(null);
            }}
          />
          {parseError && (
            <p className="text-sm font-medium text-destructive">{parseError}</p>
          )}
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={isSubmitting}>
            Abbrechen
          </Button>
          <Button onClick={handleSubmit} disabled={isSubmitting || !jsonInput.trim()}>
            {isSubmitting ? "Importiere..." : "Importieren"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
