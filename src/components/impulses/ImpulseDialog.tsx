
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

type ImpulseFormData = {
  date: string;
  impulse_text: string;
  image_url?: string;
};

type ImpulseDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (data: ImpulseFormData) => Promise<void>;
  defaultValues?: Partial<Impulse>;
  title: string;
};

export function ImpulseDialog({ open, onOpenChange, onSubmit, defaultValues, title }: ImpulseDialogProps) {
  const [isLoading, setIsLoading] = useState(false);
  const { toast } = useToast();
  const form = useForm<ImpulseFormData>({
    defaultValues: {
      date: defaultValues?.date || new Date().toISOString().split('T')[0],
      impulse_text: defaultValues?.impulse_text || '',
      image_url: defaultValues?.image_url || '',
    },
  });

  const handleSubmit = async (data: ImpulseFormData) => {
    try {
      setIsLoading(true);
      await onSubmit(data);
      onOpenChange(false);
      toast({
        title: 'Success',
        description: 'Impulse has been saved.',
      });
    } catch (error) {
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
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
        </DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-4">
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
              name="impulse_text"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Impulse Text</FormLabel>
                  <FormControl>
                    <Input {...field} />
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
                  <FormLabel>Image URL (optional)</FormLabel>
                  <FormControl>
                    <Input {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <DialogFooter>
              <Button type="submit" disabled={isLoading}>
                Save Impulse
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
