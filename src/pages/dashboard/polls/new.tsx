
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm, useFieldArray } from 'react-hook-form';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardFooter } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useCreatePoll } from '@/hooks/use-polls';
import { PlusIcon, TrashIcon } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

type FormValues = {
  question: string;
  expires_at?: string;
  options: { text: string }[];
};

const NewPollPage = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const createPoll = useCreatePoll();
  
  const { register, control, handleSubmit, formState: { errors } } = useForm<FormValues>({
    defaultValues: {
      options: [{ text: '' }, { text: '' }]
    }
  });
  
  const { fields, append, remove } = useFieldArray({
    control,
    name: "options"
  });

  const onSubmit = async (data: FormValues) => {
    try {
      await createPoll.mutateAsync({
        question: data.question,
        expires_at: data.expires_at,
        options: data.options.map(o => o.text)
      });
      
      toast({
        title: "Umfrage erstellt",
        description: "Die Umfrage wurde erfolgreich erstellt.",
      });
      
      navigate('/dashboard/polls');
    } catch (error) {
      toast({
        title: "Fehler",
        description: "Die Umfrage konnte nicht erstellt werden.",
        variant: "destructive"
      });
    }
  };

  return (
    <DashboardLayout title="Neue Umfrage">
      <div className="mb-6">
        <h2 className="text-2xl font-bold tracking-tight">Neue Umfrage erstellen</h2>
        <p className="text-muted-foreground">
          Erstelle eine neue Umfrage mit mehreren Antwortmöglichkeiten.
        </p>
      </div>

      <Card>
        <form onSubmit={handleSubmit(onSubmit)}>
          <CardContent className="space-y-6 pt-6">
            <div className="space-y-2">
              <Label htmlFor="question">Frage</Label>
              <Input
                id="question"
                {...register("question", { required: true })}
                placeholder="Wie lautet deine Frage?"
              />
              {errors.question && (
                <p className="text-sm text-destructive">Bitte gib eine Frage ein.</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="expires_at">Ablaufdatum (optional)</Label>
              <Input
                type="date"
                id="expires_at"
                {...register("expires_at")}
              />
            </div>

            <div className="space-y-4">
              <Label>Antwortmöglichkeiten</Label>
              {fields.map((field, index) => (
                <div key={field.id} className="flex gap-2">
                  <Input
                    {...register(`options.${index}.text`, { required: true })}
                    placeholder={`Option ${index + 1}`}
                  />
                  {index > 1 && (
                    <Button
                      type="button"
                      variant="outline"
                      size="icon"
                      onClick={() => remove(index)}
                    >
                      <TrashIcon className="h-4 w-4" />
                    </Button>
                  )}
                </div>
              ))}
              {errors.options && (
                <p className="text-sm text-destructive">
                  Bitte gib mindestens zwei Optionen ein.
                </p>
              )}
              <Button
                type="button"
                variant="outline"
                onClick={() => append({ text: '' })}
              >
                <PlusIcon className="mr-2 h-4 w-4" />
                Option hinzufügen
              </Button>
            </div>
          </CardContent>
          
          <CardFooter className="flex justify-end space-x-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => navigate('/dashboard/polls')}
            >
              Abbrechen
            </Button>
            <Button type="submit">
              Umfrage erstellen
            </Button>
          </CardFooter>
        </form>
      </Card>
    </DashboardLayout>
  );
};

export default NewPollPage;
