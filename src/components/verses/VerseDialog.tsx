import * as React from "react";
import { useForm } from "react-hook-form";
import { useEffect } from "react";
import { Calendar } from "@/components/ui/calendar";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { cn } from "@/lib/utils";
import { format } from "date-fns";
import { de } from "date-fns/locale";
import { CalendarIcon } from "lucide-react";
import { DailyVerse, supabase } from "@/lib/supabase";
import { RetranslateButton } from '@/components/translations/RetranslateButton';
import { VerseImageUploader } from "./VerseImageUploader";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { useState } from "react";

type FormData = Omit<DailyVerse, 'id' | 'content_id' | 'created_at' | 'content'>;


interface VerseDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (data: FormData) => void;
  initialData?: DailyVerse;
  mode: 'create' | 'edit';
}

export function VerseDialog({ open, onOpenChange, onSubmit, initialData, mode }: VerseDialogProps) {
  const defaultValues: FormData = {
    verse: '',
    reference: '',
    date: format(new Date(), 'yyyy-MM-dd'),
    image_url: '',
  };

  const form = useForm<FormData>({
    defaultValues: mode === 'create' ? defaultValues : {
      verse: initialData?.verse || '',
      reference: initialData?.reference || '',
      date: initialData?.date ? format(new Date(initialData.date), 'yyyy-MM-dd') : format(new Date(), 'yyyy-MM-dd'),
      image_url: initialData?.image_url || '',
    },
  });

  useEffect(() => {
    if (open) {
      if (mode === 'create') {
        form.reset(defaultValues);
      } else if (initialData) {
        form.reset({
          verse: initialData.verse,
          reference: initialData.reference,
          date: format(new Date(initialData.date), 'yyyy-MM-dd'),
          image_url: initialData.image_url || '',
        });
      }
    }
  }, [open, mode, initialData, form]);

  const [duplicates, setDuplicates] = useState<Array<{ id: string; date: string; reference: string }>>([]);
  const [pendingData, setPendingData] = useState<FormData | null>(null);
  const [checking, setChecking] = useState(false);

  const proceedSubmit = (data: FormData) => {
    // A changed/cleared image is no longer the automatically generated one:
    // null = manual upload (never overwritten) or empty (gets regenerated).
    const imageChanged = (data.image_url || '') !== (initialData?.image_url || '');
    onSubmit({
      ...data,
      image_source_hash: mode === 'edit' && !imageChanged ? undefined : null,
    });
    setPendingData(null);
    setDuplicates([]);
  };

  const handleSubmit = async (data: FormData) => {
    setChecking(true);
    try {
      // Same verse (reference or text) in the same calendar year or within 365 days?
      const { data: rows, error } = await supabase.rpc('check_verse_conflicts', {
        p_verse: data.verse,
        p_reference: data.reference,
        p_date: data.date,
        p_exclude_id: initialData?.id ?? null,
      });

      if (!error && rows && rows.length > 0) {
        setDuplicates(rows);
        setPendingData(data);
        setChecking(false);
        return;
      }
      if (error) console.error('Duplicate check failed', error);
    } catch (e) {
      console.error('Duplicate check failed', e);
    }
    setChecking(false);
    proceedSubmit(data);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>{mode === 'create' ? 'Neuer Vers des Tages' : 'Vers des Tages bearbeiten'}</DialogTitle>
          <DialogDescription>
            {mode === 'create' ? 'Füge einen neuen Vers des Tages hinzu.' : 'Bearbeite den ausgewählten Vers.'}
          </DialogDescription>
        </DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-4">
            <FormField
              control={form.control}
              name="date"
              render={({ field }) => (
                <FormItem className="flex flex-col">
                  <FormLabel>Datum</FormLabel>
                  <Popover>
                    <PopoverTrigger asChild>
                      <FormControl>
                        <Button
                          variant={"outline"}
                          className={cn(
                            "w-full pl-3 text-left font-normal",
                            !field.value && "text-muted-foreground"
                          )}
                          disabled={mode === 'edit'}
                        >
                          {field.value ? (
                            format(new Date(field.value), "PPP", { locale: de })
                          ) : (
                            <span>Datum auswählen</span>
                          )}
                          <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
                        </Button>
                      </FormControl>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0" align="start">
                      <Calendar
                        mode="single"
                        selected={field.value ? new Date(field.value) : undefined}
                        onSelect={(date) => field.onChange(date ? format(date, 'yyyy-MM-dd') : '')}
                        disabled={(date) => date < new Date('1900-01-01')}
                        locale={de}
                        className="pointer-events-auto"
                      />
                    </PopoverContent>
                  </Popover>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="verse"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Vers</FormLabel>
                  <FormControl>
                    <Textarea placeholder="Gib den Vers ein" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="reference"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Referenz</FormLabel>
                  <FormControl>
                    <Input placeholder="z.B. Johannes 3,16" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="image_url"
              render={({ field }) => (
                <FormItem>
                  <FormControl>
                    <VerseImageUploader
                      value={field.value || ''}
                      onChange={(url) => field.onChange(url)}
                    />
                  </FormControl>
                  <p className="text-xs text-muted-foreground">
                    {field.value && initialData?.image_source_hash && field.value === initialData.image_url
                      ? 'Automatisch erzeugtes Naturbild – wird bei Text-Änderungen neu erzeugt.'
                      : 'Ohne eigenes Bild wird automatisch ein Naturbild erzeugt (ca. 45 Tage vorher).'}
                  </p>
                  {field.value && (
                    <Button
                      type="button"
                      variant="link"
                      size="sm"
                      className="h-auto p-0 text-xs"
                      onClick={() => field.onChange('')}
                    >
                      Bild entfernen &amp; automatisch neu erzeugen lassen
                    </Button>
                  )}
                  <FormMessage />
                </FormItem>
              )}
            />
            {mode === 'edit' && initialData?.usage_count !== undefined && (
              <div className="flex items-center justify-between rounded-md border p-3 text-sm">
                <span className="text-muted-foreground">Teilen/Downloads</span>
                <span className="font-mono font-medium">{initialData.usage_count}</span>
              </div>
            )}
            <DialogFooter className="gap-2 sm:justify-between">
              {mode === 'edit' && initialData?.content_id && (
                <RetranslateButton contentId={initialData.content_id} />
              )}
              <Button type="submit" disabled={checking}>
                {checking ? 'Prüfe…' : mode === 'create' ? 'Erstellen' : 'Speichern'}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>

      <AlertDialog
        open={duplicates.length > 0}
        onOpenChange={(o) => { if (!o) { setDuplicates([]); setPendingData(null); } }}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Vers wurde bereits verwendet</AlertDialogTitle>
            <AlertDialogDescription asChild>
              <div className="space-y-2">
                <p>
                  Dieser Vers ist im selben Kalenderjahr oder mit weniger als 365 Tagen Abstand
                  bereits Vers des Tages:
                </p>
                <ul className="list-disc pl-5">
                  {duplicates.map((d) => (
                    <li key={d.id}>
                      {format(new Date(d.date), 'dd. MMMM yyyy', { locale: de })} – {d.reference}
                    </li>
                  ))}
                </ul>
                <p>Trotzdem speichern?</p>
              </div>
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Abbrechen</AlertDialogCancel>
            <AlertDialogAction onClick={() => pendingData && proceedSubmit(pendingData)}>
              Trotzdem speichern
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Dialog>
  );
}
