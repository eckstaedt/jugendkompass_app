
import { useState } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { ImpulseDialog } from '@/components/impulses/ImpulseDialog';
import { useImpulses, useCreateImpulse, useUpdateImpulse } from '@/hooks/use-impulses';
import { Plus } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { format } from 'date-fns';
import { de } from 'date-fns/locale';

export default function ImpulsesPage() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingImpulse, setEditingImpulse] = useState<null | any>(null);
  
  const { data: impulses, isLoading } = useImpulses();
  const createImpulse = useCreateImpulse();
  const updateImpulse = useUpdateImpulse();
  const { toast } = useToast();

  const handleSubmit = async (data: any) => {
    try {
      if (editingImpulse) {
        await updateImpulse.mutateAsync({ id: editingImpulse.id, ...data });
      } else {
        await createImpulse.mutateAsync(data);
      }
    } catch (error) {
      console.error("Error saving impulse:", error);
      toast({
        title: "Error",
        description: "Fehler beim Speichern des Impulses. Bitte versuchen Sie es erneut.",
        variant: "destructive",
      });
      throw error;
    }
  };

  return (
    <DashboardLayout title="Impuls">
      <div className="mb-4">
        <Button
          onClick={() => {
            setEditingImpulse(null);
            setDialogOpen(true);
          }}
        >
          <Plus className="mr-2 h-4 w-4" />
          Neuer Impuls
        </Button>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center h-32">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
        </div>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Datum</TableHead>
                <TableHead>Text</TableHead>
                <TableHead>Bild</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {impulses?.map((impulse) => (
                <TableRow 
                  key={impulse.id}
                  className="cursor-pointer hover:bg-muted/50"
                  onClick={() => {
                    setEditingImpulse(impulse);
                    setDialogOpen(true);
                  }}
                >
                  <TableCell>{format(new Date(impulse.date), "dd. MMMM yyyy", { locale: de })}</TableCell>
                  <TableCell>
                    <div className="max-w-md overflow-hidden text-ellipsis">
                      <div dangerouslySetInnerHTML={{ __html: impulse.impulse_text.substring(0, 150) + '...' }} />
                    </div>
                  </TableCell>
                  <TableCell>
                    {impulse.image_url && (
                      <img
                        src={impulse.image_url}
                        alt="Impuls"
                        className="w-16 h-16 object-cover rounded"
                      />
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      <ImpulseDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        onSubmit={handleSubmit}
        defaultValues={editingImpulse}
        title={editingImpulse ? 'Impuls bearbeiten' : 'Neuer Impuls'}
      />
    </DashboardLayout>
  );
}
