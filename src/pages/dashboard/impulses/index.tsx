
import { useState } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { ImpulseDialog } from '@/components/impulses/ImpulseDialog';
import { useImpulses, useCreateImpulse, useUpdateImpulse } from '@/hooks/use-impulses';
import { Plus } from 'lucide-react';

export default function ImpulsesPage() {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingImpulse, setEditingImpulse] = useState<null | any>(null);
  
  const { data: impulses, isLoading } = useImpulses();
  const createImpulse = useCreateImpulse();
  const updateImpulse = useUpdateImpulse();

  const handleSubmit = async (data: any) => {
    if (editingImpulse) {
      await updateImpulse.mutateAsync({ id: editingImpulse.id, ...data });
    } else {
      await createImpulse.mutateAsync(data);
    }
  };

  return (
    <DashboardLayout title="Impulses">
      <div className="mb-4">
        <Button
          onClick={() => {
            setEditingImpulse(null);
            setDialogOpen(true);
          }}
        >
          <Plus className="mr-2 h-4 w-4" />
          New Impulse
        </Button>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center h-32">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
        </div>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {impulses?.map((impulse) => (
            <Card 
              key={impulse.id} 
              className="cursor-pointer hover:shadow-md transition-shadow"
              onClick={() => {
                setEditingImpulse(impulse);
                setDialogOpen(true);
              }}
            >
              <CardHeader>
                <CardTitle>{new Date(impulse.date).toLocaleDateString()}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div dangerouslySetInnerHTML={{ __html: impulse.impulse_text }} />
                {impulse.image_url && (
                  <img
                    src={impulse.image_url}
                    alt="Impulse"
                    className="w-full rounded-md max-h-40 object-cover"
                  />
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <ImpulseDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        onSubmit={handleSubmit}
        defaultValues={editingImpulse}
        title={editingImpulse ? 'Edit Impulse' : 'New Impulse'}
      />
    </DashboardLayout>
  );
}
