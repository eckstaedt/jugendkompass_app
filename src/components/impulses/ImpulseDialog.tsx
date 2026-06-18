
import { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';
import { Impulse } from '@/hooks/use-impulses';
import RichTextEditor from '@/components/editor/RichTextEditor';
import { LoaderCircle, Upload, Send, Megaphone } from 'lucide-react';
import { RetranslateButton } from '@/components/translations/RetranslateButton';
import { useTestPushDevices, useSendTestPush } from '@/hooks/use-test-push-devices';
import { supabase } from '@/integrations/supabase/client';
import { useQueryClient } from '@tanstack/react-query';

const getEdgeFunctionErrorMessage = async (error: unknown) => {
  const context = (error as { context?: Response })?.context;
  if (context) {
    try {
      const payload = await context.clone().json();
      if (typeof payload?.error === 'string') return payload.error;
    } catch {
      // Fall back to the default error message below.
    }
  }
  return (error as Error).message;
};

type ImpulseFormData = {
  date: string;
  title: string;
  impulse_text: string;
  notification_title: string;
  notification_body: string;
  image: FileList;
};

type ImpulseDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (data: {
    date: string;
    title: string;
    impulse_text: string;
    notification_title?: string | null;
    notification_body?: string | null;
    image?: File;
    image_url?: string;
  }) => Promise<void>;
  defaultValues?: Partial<Impulse>;
  title: string;
};

export function ImpulseDialog({ open, onOpenChange, onSubmit, defaultValues, title }: ImpulseDialogProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [isDispatching, setIsDispatching] = useState(false);
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const isEdit = Boolean(defaultValues?.id);
  const { data: testDevices = [] } = useTestPushDevices();
  const { mutate: sendTestPush, isPending: isSendingTestPush } = useSendTestPush();

  const form = useForm<ImpulseFormData>({
    defaultValues: {
      date: defaultValues?.date || new Date().toISOString().split('T')[0],
      title: defaultValues?.title || '',
      impulse_text: defaultValues?.impulse_text || '',
      notification_title: defaultValues?.notification_title || '',
      notification_body: defaultValues?.notification_body || '',
    },
  });

  useEffect(() => {
    if (open) {
      form.reset({
        date: defaultValues?.date || new Date().toISOString().split('T')[0],
        title: defaultValues?.title || '',
        impulse_text: defaultValues?.impulse_text || '',
        notification_title: defaultValues?.notification_title || '',
        notification_body: defaultValues?.notification_body || '',
        image: undefined as any,
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, defaultValues?.id]);

  const handleSubmit = async (data: ImpulseFormData) => {
    const file = data.image?.[0];
    if (!isEdit && !file) {
      toast({
        title: "Error",
        description: "Please select an image",
        variant: "destructive",
      });
      return;
    }

    try {
      setIsLoading(true);
      await onSubmit({
        date: data.date,
        title: data.title,
        impulse_text: data.impulse_text,
        notification_title: data.notification_title.trim() || null,
        notification_body: data.notification_body.trim() || null,
        ...(file ? { image: file } : { image_url: defaultValues?.image_url }),
      });
      onOpenChange(false);
      toast({
        title: 'Success',
        description: 'Impulse has been saved.',
      });
    } catch (error) {
      console.error("Failed to save impulse:", error);
      toast({
        title: 'Error',
        description: 'Failed to save impulse.',
        variant: 'destructive',
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleTestPush = () => {
    if (testDevices.length === 0) {
      toast({ title: 'Keine Test-Geräte', description: 'Bitte zuerst Test-Push-Geräte anlegen.', variant: 'destructive' });
      return;
    }
    const values = form.getValues();
    const t = values.notification_title.trim() || values.title.trim() || 'Neuer Impuls';
    const b = values.notification_body.trim() || 'Schau dir den neuen Impuls an';
    sendTestPush(
      {
        device_ids: testDevices.map((d) => d.id),
        title: t,
        body: b,
        data: {
          type: 'impulse',
          content_id: defaultValues?.content_id ?? '',
          entity_id: defaultValues?.id ?? '',
        },
        image_url: defaultValues?.image_url ?? undefined,
      },
      {
        onSuccess: (res) => {
          const ok = res.results.filter((r) => r.ok).length;
          const fail = res.results.length - ok;
          toast({
            title: 'Test-Push gesendet',
            description: `${ok} erfolgreich, ${fail} fehlgeschlagen`,
            variant: fail === 0 ? 'success' : 'destructive',
          });
        },
        onError: (e) => {
          toast({ title: 'Fehler', description: (e as Error).message, variant: 'destructive' });
        },
      },
    );
  };

  const handleDispatchPush = async () => {
    if (!defaultValues?.id) return;
    const values = form.getValues();
    const savedTitle = defaultValues.notification_title?.trim() ?? '';
    const savedBody = defaultValues.notification_body?.trim() ?? '';
    const formTitle = values.notification_title.trim();
    const formBody = values.notification_body.trim();
    if (!savedTitle) {
      toast({ title: 'Kein Push-Titel gespeichert', description: 'Bitte zuerst Push-Titel hinterlegen und speichern.', variant: 'destructive' });
      return;
    }
    if (formTitle !== savedTitle || formBody !== savedBody) {
      toast({ title: 'Änderungen nicht gespeichert', description: 'Bitte Push-Titel und Push-Text vor dem Senden speichern.', variant: 'destructive' });
      return;
    }
    if (defaultValues.notification_sent_at) {
      toast({ title: 'Bereits gesendet', description: 'Diese Push wurde bereits versendet.', variant: 'destructive' });
      return;
    }
    const ok = window.confirm(`Push für diesen Impuls jetzt an ALLE App-Nutzer senden? Dies kann nicht rückgängig gemacht werden.`);
    if (!ok) return;
    setIsDispatching(true);
    try {
      const { data, error } = await supabase.functions.invoke('dispatch-impulse-pushes', {
        body: { impulse_id: defaultValues.id },
      });
      if (error) throw error;
      toast({
        title: 'Push gesendet',
        description: `${data?.sent ?? 0} von ${data?.total ?? 0} Geräten erreicht`,
        variant: 'success',
      });
      queryClient.invalidateQueries({ queryKey: ['impulses'] });
      onOpenChange(false);
    } catch (e) {
      toast({ title: 'Fehler', description: await getEdgeFunctionErrorMessage(e), variant: 'destructive' });
    } finally {
      setIsDispatching(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[750px] max-h-[90vh] overflow-y-auto flex flex-col">
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
        </DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-6">
            <FormField
              control={form.control}
              name="date"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Date</FormLabel>
                  <FormControl>
                    <Input type="date" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="title"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Titel</FormLabel>
                  <FormControl>
                    <Input placeholder="Titel des Impulses" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="impulse_text"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Impulse Text</FormLabel>
                  <FormControl>
                    <RichTextEditor content={field.value} onChange={field.onChange} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="image"
              render={({ field: { onChange, value, ...field } }) => (
                <FormItem>
                  <FormLabel>{isEdit ? 'Bild ersetzen (optional)' : 'Image (required)'}</FormLabel>
                  <FormControl>
                    <Input
                      type="file"
                      accept="image/*"
                      onChange={(e) => onChange(e.target.files)}
                      {...field}
                    />
                  </FormControl>
                  {isEdit && defaultValues?.image_url && (
                    <img src={defaultValues.image_url} alt="aktuell" className="mt-2 h-20 w-20 rounded object-cover" />
                  )}
                  <FormMessage />
                </FormItem>
              )}
            />

            <div className="rounded-lg border border-dashed p-3 grid gap-3">
              <p className="text-sm font-medium">Push-Benachrichtigung (optional)</p>
              <p className="text-xs text-muted-foreground">
                Wird in alle Sprachen übersetzt. Manueller Versand über den Megafon-Button.
              </p>
              <FormField
                control={form.control}
                name="notification_title"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Push-Titel</FormLabel>
                    <FormControl>
                      <Input placeholder="z.B. Neuer Impuls verfügbar" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="notification_body"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Push-Text</FormLabel>
                    <FormControl>
                      <Textarea placeholder="Kurzer Text für die Benachrichtigung..." rows={2} {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              {isEdit && defaultValues?.notification_sent_at && (
                <p className="text-xs text-muted-foreground">
                  Push gesendet: {new Date(defaultValues.notification_sent_at).toLocaleString('de-DE', { dateStyle: 'medium', timeStyle: 'short' })}
                </p>
              )}
              {isEdit && (
                <div className="flex flex-wrap gap-2 pt-1">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={handleTestPush}
                    disabled={isSendingTestPush}
                  >
                    <Send className="mr-2 h-4 w-4" />
                    {isSendingTestPush ? 'Sende...' : 'Test-Push'}
                  </Button>
                  {!defaultValues?.notification_sent_at && (
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={handleDispatchPush}
                      disabled={isDispatching}
                    >
                      <Megaphone className="mr-2 h-4 w-4" />
                      {isDispatching ? 'Sende...' : 'An alle senden'}
                    </Button>
                  )}
                </div>
              )}
            </div>

            <DialogFooter className="gap-2 sm:justify-between">
              {defaultValues?.content_id && (
                <RetranslateButton contentId={defaultValues.content_id} />
              )}
              <Button type="submit" disabled={isLoading}>
                {isLoading ? (
                  <>
                    <LoaderCircle className="mr-2 h-4 w-4 animate-spin" />
                    Saving...
                  </>
                ) : (
                  <>
                    <Upload className="mr-2 h-4 w-4" />
                    Save Impulse
                  </>
                )}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
