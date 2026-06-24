import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import SubscriptionForm from '@/components/subscriptions/SubscriptionForm';
import {
  useSubscriptions,
  useCreateSubscription,
  useDeleteSubscription,
  useUpdateSubscriptionPaid,
} from '@/hooks/use-subscriptions';
import { useToast } from '@/hooks/use-toast';
import { Button } from '@/components/ui/button';
import { Trash2 } from 'lucide-react';
import { format } from 'date-fns';
import { Checkbox } from '@/components/ui/checkbox';

const SubscriptionsPage = () => {
  const { data: subs, isLoading } = useSubscriptions();
  const create = useCreateSubscription();
  const del = useDeleteSubscription();
  const updatePaid = useUpdateSubscriptionPaid();
  const { toast } = useToast();

  return (
    <DashboardLayout title="Print-Abonnements">
      <div className="max-w-4xl mx-auto space-y-8">
        <div className="bg-card rounded-lg border p-6">
          <h2 className="text-lg font-semibold mb-4">Neues Abonnement</h2>
          <SubscriptionForm
            isSubmitting={create.isPending}
            onSubmit={async (input) => {
              try {
                await create.mutateAsync(input);
                toast({ title: 'Erfolg', description: 'Abonnement wurde angelegt.' });
              } catch (e) {
                toast({
                  title: 'Fehler',
                  description: (e as Error).message,
                  variant: 'destructive',
                });
              }
            }}
          />
        </div>

        <div className="bg-card rounded-lg border p-6">
          <h2 className="text-lg font-semibold mb-4">Bestehende Abonnements</h2>
          {isLoading ? (
            <div>Lädt...</div>
          ) : !subs || subs.length === 0 ? (
            <div className="text-muted-foreground text-sm">Noch keine Abonnements vorhanden.</div>
          ) : (
            <div className="space-y-3">
              {subs.map((s) => (
                <div key={s.id} className="border rounded-md p-4 flex justify-between gap-4">
                  <div className="text-sm space-y-1">
                    <div className="font-medium">
                      {s.first_name} {s.last_name}{' '}
                      <span className="text-muted-foreground">({s.email})</span>
                    </div>
                    {s.phone && <div className="text-muted-foreground">Tel: {s.phone}</div>}
                    <div>
                      {s.street}
                      {s.address_extra ? `, ${s.address_extra}` : ''}, {s.postal_code} {s.city},{' '}
                      {s.country}
                    </div>
                    <div className="text-muted-foreground">
                      Versand: {s.shipping_method === 'pickup' ? 'Abholung' : 'Standardversand'} ·{' '}
                      {format(new Date(s.created_at), 'dd.MM.yyyy HH:mm')}
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <label className="flex items-center gap-2 text-sm">
                      <Checkbox
                        checked={Boolean(s.paid)}
                        onCheckedChange={async (checked) => {
                          try {
                            await updatePaid.mutateAsync({ id: s.id, paid: checked === true });
                            toast({ title: 'Gespeichert', description: 'Bezahlt-Status wurde aktualisiert.' });
                          } catch (e) {
                            toast({
                              title: 'Fehler',
                              description: (e as Error).message,
                              variant: 'destructive',
                            });
                          }
                        }}
                      />
                      <span>Bezahlt</span>
                    </label>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={async () => {
                        if (!confirm('Abonnement wirklich löschen?')) return;
                        try {
                          await del.mutateAsync(s.id);
                          toast({ title: 'Gelöscht', description: 'Abo wurde gelöscht.' });
                        } catch (e) {
                          toast({
                            title: 'Fehler',
                            description: (e as Error).message,
                            variant: 'destructive',
                          });
                        }
                      }}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
};

export default SubscriptionsPage;
