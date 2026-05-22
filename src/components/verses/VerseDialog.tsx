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
import { DailyVerse } from "@/lib/supabase";
import { RetranslateButton } from '@/components/translations/RetranslateButton';
import { VerseImageUploader } from "./VerseImageUploader";
import { toast } from "sonner";

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

  const handleSubmit = (data: FormData) => {
    if (!data.image_url) {
      toast.error("Bitte ein Bild hochladen.");
      return;
    }
    onSubmit(data);
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
                      required
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <DialogFooter className="gap-2 sm:justify-between">
              {mode === 'edit' && initialData?.content_id && (
                <RetranslateButton contentId={initialData.content_id} />
              )}
              <Button type="submit">{mode === 'create' ? 'Erstellen' : 'Speichern'}</Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
