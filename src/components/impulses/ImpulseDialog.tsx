
import { useState } from 'react';
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
import { useToast } from '@/hooks/use-toast';
import { Impulse } from '@/hooks/use-impulses';
import RichTextEditor from '@/components/editor/RichTextEditor';
import { LoaderCircle, Upload } from 'lucide-react';
import { RetranslateButton } from '@/components/translations/RetranslateButton';

type ImpulseFormData = {
  date: string;
  title: string;
  impulse_text: string;
  image: FileList;
};

type ImpulseDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (data: { date: string; title: string; impulse_text: string; image: File }) => Promise<void>;
  defaultValues?: Partial<Impulse>;
  title: string;
};

export function ImpulseDialog({ open, onOpenChange, onSubmit, defaultValues, title }: ImpulseDialogProps) {
  const [isLoading, setIsLoading] = useState(false);
  const { toast } = useToast();
  const form = useForm<ImpulseFormData>({
    defaultValues: {
      date: defaultValues?.date || new Date().toISOString().split('T')[0],
      title: defaultValues?.title || '',
      impulse_text: defaultValues?.impulse_text || '',
    },
  });

  const handleSubmit = async (data: ImpulseFormData) => {
    if (!data.image?.[0]) {
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
        image: data.image[0]
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

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[750px]">
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
                  <FormLabel>Image (required)</FormLabel>
                  <FormControl>
                    <Input 
                      type="file" 
                      accept="image/*"
                      onChange={(e) => onChange(e.target.files)}
                      {...field}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
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
