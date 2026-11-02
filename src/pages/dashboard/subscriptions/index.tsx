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
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useMemo, useState } from 'react';

type PaidFilter = 'all' | 'open' | 'paid';

const SubscriptionsPage = () => {
  const { data: subs, isLoading } = useSubscriptions();
  const create = useCreateSubscription();
  const del = useDeleteSubscription();
  const updatePaid = useUpdateSubscriptionPaid();
  const { toast } = useToast();
  const [filter, setFilter] = useState<PaidFilter>('all');

  const counts = useMemo(() => {
    const all = subs?.length ?? 0;
    const paid = subs?.filter((s) => s.paid).length ?? 0;
    return { all, paid, open: all - paid };
  }, [subs]);

  const visible = useMemo(
    () =>
      (subs ?? []).filter((s) =>
        filter === 'all' ? true : filter === 'paid' ? s.paid : !s.paid,
      ),
    [subs, filter],
  );

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
          <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
            <h2 className="text-lg font-semibold">Bestehende Abonnements</h2>
            <Tabs value={filter} onValueChange={(v) => setFilter(v as PaidFilter)}>
              <TabsList>
                <TabsTrigger value="all">Alle ({counts.all})</TabsTrigger>
                <TabsTrigger value="open">Offen ({counts.open})</TabsTrigger>
                <TabsTrigger value="paid">Bezahlt ({counts.paid})</TabsTrigger>
              </TabsList>
            </Tabs>
          </div>
          {isLoading ? (
            <div>Lädt...</div>
          ) : !subs || subs.length === 0 ? (
            <div className="text-muted-foreground text-sm">Noch keine Abonnements vorhanden.</div>
          ) : visible.length === 0 ? (
            <div className="text-muted-foreground text-sm">Keine Abonnements in dieser Ansicht.</div>
          ) : (
            <div className="space-y-3">
              {visible.map((s) => (
                <div key={s.id} className="border rounded-md p-4 flex justify-between gap-4">
                  <div className="text-sm space-y-1">
                    <div className="font-medium flex flex-wrap items-center gap-2">
                      <span>
                        {s.first_name} {s.last_name}{' '}
                        <span className="text-muted-foreground">({s.email})</span>
                      </span>
                      {s.paid ? (
                        <Badge className="bg-green-600 hover:bg-green-600">Bezahlt</Badge>
                      ) : (
                        <Badge variant="outline">Offen</Badge>
                      )}
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
                    {s.paid && s.paid_at && (
                      <div className="text-green-700 dark:text-green-500">
                        Bezahlt am {format(new Date(s.paid_at), 'dd.MM.yyyy HH:mm')}
                      </div>
                    )}
                  </div>
                  <div className="flex items-center gap-3">
                    <label className="flex items-center gap-2 text-sm cursor-pointer">
                      <Checkbox
                        checked={Boolean(s.paid)}
                        disabled={updatePaid.isPending && updatePaid.variables?.id === s.id}
                        onCheckedChange={async (checked) => {
                          try {
                            await updatePaid.mutateAsync({ id: s.id, paid: checked === true });
                            toast({
                              title: 'Gespeichert',
                              description:
                                checked === true
                                  ? `${s.first_name} ${s.last_name} als bezahlt markiert.`
                                  : `${s.first_name} ${s.last_name} als offen markiert.`,
                            });
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
