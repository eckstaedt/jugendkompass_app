
import * as React from "react";
import { useForm } from "react-hook-form";
import { useEffect } from "react"; // Added this import
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
import { DailyVerse } from "@/hooks/use-daily-verses";

type FormData = Omit<DailyVerse, 'id' | 'content_id'>;

interface VerseDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (data: FormData) => void;
  initialData?: DailyVerse;
  mode: 'create' | 'edit';
}

export function VerseDialog({ open, onOpenChange, onSubmit, initialData, mode }: VerseDialogProps) {
  const defaultValues = {
    verse: '',
    reference: '',
    date: format(new Date(), 'yyyy-MM-dd'),
  };

  const form = useForm<FormData>({
    defaultValues: mode === 'create' ? defaultValues : {
      verse: initialData?.verse || '',
      reference: initialData?.reference || '',
      date: initialData?.date ? format(new Date(initialData.date), 'yyyy-MM-dd') : format(new Date(), 'yyyy-MM-dd'),
    },
  });

  // Reset form when dialog opens/closes or mode changes
  useEffect(() => {
    if (open) {
      if (mode === 'create') {
        form.reset(defaultValues);
      } else if (initialData) {
        form.reset({
          verse: initialData.verse,
          reference: initialData.reference,
          date: format(new Date(initialData.date), 'yyyy-MM-dd'),
        });
      }
    }
  }, [open, mode, initialData, form]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>{mode === 'create' ? 'Neuer Tagesvers' : 'Tagesvers bearbeiten'}</DialogTitle>
          <DialogDescription>
            {mode === 'create' ? 'Füge einen neuen Tagesvers hinzu.' : 'Bearbeite den ausgewählten Tagesvers.'}
          </DialogDescription>
        </DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
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
                          disabled={mode === 'edit'} // Disable date button when editing
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
                        disabled={(date) =>
                          date < new Date('1900-01-01')
                        }
                        locale={de}
                        className="pointer-events-auto" // Added to make calendar interactive
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
                    <Textarea
                      placeholder="Gib den Vers ein"
                      {...field}
                    />
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
            <DialogFooter>
              <Button type="submit">{mode === 'create' ? 'Erstellen' : 'Speichern'}</Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
