import { useMemo, useState } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Checkbox } from '@/components/ui/checkbox';
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from '@/components/ui/card';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { Loader2, Plus, Send, Trash2, CheckCircle2, XCircle } from 'lucide-react';
import {
  TestPushDevice,
  TestPushResult,
  useCreateTestPushDevice,
  useDeleteTestPushDevice,
  useSendTestPush,
  useTestPushDevices,
} from '@/hooks/use-test-push-devices';

const LANGUAGES = [
  { code: 'de', label: 'Deutsch' },
  { code: 'en', label: 'English' },
  { code: 'es', label: 'Español' },
  { code: 'ru', label: 'Русский' },
  { code: 'pl', label: 'Polski' },
];

const PLATFORMS = [
  { code: 'ios', label: 'iOS' },
  { code: 'android', label: 'Android' },
];

const TestPushPage = () => {
  const { toast } = useToast();
  const { data: devices, isLoading } = useTestPushDevices();
  const createDevice = useCreateTestPushDevice();
  const deleteDevice = useDeleteTestPushDevice();
  const sendPush = useSendTestPush();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState({
    label: '',
    fcm_token: '',
    platform: 'ios',
    language: 'de',
  });

  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [title, setTitle] = useState('Test-Push 🚀');
  const [body, setBody] = useState('Das ist eine Test-Benachrichtigung aus dem Admin-Dashboard.');
  const [results, setResults] = useState<TestPushResult[] | null>(null);

  const selectedIds = useMemo(
    () => Object.entries(selected).filter(([, v]) => v).map(([k]) => k),
    [selected],
  );
  const allSelected = (devices?.length ?? 0) > 0 && selectedIds.length === devices?.length;

  const toggleAll = () => {
    if (!devices) return;
    if (allSelected) setSelected({});
    else setSelected(Object.fromEntries(devices.map((d) => [d.id, true])));
  };

  const handleCreate = async () => {
    if (!form.label.trim() || !form.fcm_token.trim()) {
      toast({ title: 'Fehler', description: 'Label und FCM-Token sind erforderlich.', variant: 'destructive' });
      return;
    }
    try {
      await createDevice.mutateAsync({
        label: form.label.trim(),
        fcm_token: form.fcm_token.trim(),
        platform: form.platform || null,
        language: form.language,
      });
      setForm({ label: '', fcm_token: '', platform: 'ios', language: 'de' });
      setDialogOpen(false);
    } catch (e) {
      toast({ title: 'Fehler', description: (e as Error).message, variant: 'destructive' });
    }
  };

  const handleDelete = async (d: TestPushDevice) => {
    if (!confirm(`Gerät "${d.label}" wirklich löschen?`)) return;
    try {
      await deleteDevice.mutateAsync(d.id);
      setSelected((s) => {
        const c = { ...s };
        delete c[d.id];
        return c;
      });
    } catch (e) {
      toast({ title: 'Fehler', description: (e as Error).message, variant: 'destructive' });
    }
  };

  const handleSend = async () => {
    if (selectedIds.length === 0) {
      toast({ title: 'Hinweis', description: 'Bitte mindestens ein Gerät auswählen.' });
      return;
    }
    if (!title.trim() || !body.trim()) {
      toast({ title: 'Fehler', description: 'Titel und Text sind erforderlich.', variant: 'destructive' });
      return;
    }
    setResults(null);
    try {
      const res = await sendPush.mutateAsync({
        device_ids: selectedIds,
        title: title.trim(),
        body: body.trim(),
      });
      setResults(res.results);
      const ok = res.results.filter((r) => r.ok).length;
      toast({
        title: 'Gesendet',
        description: `${ok}/${res.results.length} Push(s) erfolgreich.`,
      });
    } catch (e) {
      toast({ title: 'Fehler', description: (e as Error).message, variant: 'destructive' });
    }
  };

  return (
    <DashboardLayout title="Test Pushes">
      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <div>
              <CardTitle>Test-Geräte</CardTitle>
              <CardDescription>
                FCM-Tokens für manuelle Push-Tests verwalten.
              </CardDescription>
            </div>
            <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
              <DialogTrigger asChild>
                <Button size="sm">
                  <Plus className="h-4 w-4 mr-1" /> Gerät
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Test-Gerät hinzufügen</DialogTitle>
                </DialogHeader>
                <div className="space-y-3">
                  <div>
                    <Label>Label</Label>
                    <Input
                      value={form.label}
                      onChange={(e) => setForm({ ...form, label: e.target.value })}
                      placeholder="z. B. iPhone Andi"
                    />
                  </div>
                  <div>
                    <Label>FCM-Token</Label>
                    <Textarea
                      value={form.fcm_token}
                      onChange={(e) => setForm({ ...form, fcm_token: e.target.value })}
                      placeholder="FCM Device Token"
                      rows={4}
                      className="font-mono text-xs"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <Label>Plattform</Label>
                      <Select
                        value={form.platform}
                        onValueChange={(v) => setForm({ ...form, platform: v })}
                      >
                        <SelectTrigger><SelectValue /></SelectTrigger>
                        <SelectContent>
                          {PLATFORMS.map((p) => (
                            <SelectItem key={p.code} value={p.code}>{p.label}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                    <div>
                      <Label>Sprache</Label>
                      <Select
                        value={form.language}
                        onValueChange={(v) => setForm({ ...form, language: v })}
                      >
                        <SelectTrigger><SelectValue /></SelectTrigger>
                        <SelectContent>
                          {LANGUAGES.map((l) => (
                            <SelectItem key={l.code} value={l.code}>{l.label}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>
                </div>
                <DialogFooter>
                  <Button variant="outline" onClick={() => setDialogOpen(false)}>Abbrechen</Button>
                  <Button onClick={handleCreate} disabled={createDevice.isPending}>
                    {createDevice.isPending && <Loader2 className="h-4 w-4 mr-1 animate-spin" />}
                    Speichern
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="flex justify-center py-8">
                <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
              </div>
            ) : !devices || devices.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-8">
                Noch keine Test-Geräte. Füge eines hinzu, um Pushes zu testen.
              </p>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-8">
                      <Checkbox checked={allSelected} onCheckedChange={toggleAll} />
                    </TableHead>
                    <TableHead>Label</TableHead>
                    <TableHead>Sprache</TableHead>
                    <TableHead>Token</TableHead>
                    <TableHead className="w-10"></TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {devices.map((d) => (
                    <TableRow key={d.id}>
                      <TableCell>
                        <Checkbox
                          checked={!!selected[d.id]}
                          onCheckedChange={(v) =>
                            setSelected((s) => ({ ...s, [d.id]: !!v }))
                          }
                        />
                      </TableCell>
                      <TableCell>
                        <div className="font-medium">{d.label}</div>
                        {d.platform && (
                          <div className="text-xs text-muted-foreground">{d.platform}</div>
                        )}
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{d.language.toUpperCase()}</Badge>
                      </TableCell>
                      <TableCell className="font-mono text-xs text-muted-foreground max-w-[140px] truncate">
                        {d.fcm_token}
                      </TableCell>
                      <TableCell>
                        <Button
                          size="icon"
                          variant="ghost"
                          onClick={() => handleDelete(d)}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Test-Push senden</CardTitle>
            <CardDescription>
              Sendet eine Push direkt an die ausgewählten Geräte ({selectedIds.length} ausgewählt).
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <div>
              <Label>Titel</Label>
              <Input value={title} onChange={(e) => setTitle(e.target.value)} />
            </div>
            <div>
              <Label>Text</Label>
              <Textarea value={body} onChange={(e) => setBody(e.target.value)} rows={4} />
            </div>
            <Button
              onClick={handleSend}
              disabled={sendPush.isPending || selectedIds.length === 0}
              className="w-full"
            >
              {sendPush.isPending ? (
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              ) : (
                <Send className="h-4 w-4 mr-2" />
              )}
              An {selectedIds.length} Gerät(e) senden
            </Button>

            {results && (
              <div className="mt-4 space-y-2">
                <h4 className="text-sm font-medium">Ergebnis</h4>
                {results.map((r) => (
                  <div
                    key={r.id}
                    className="flex items-start gap-2 rounded-md border p-2 text-sm"
                  >
                    {r.ok ? (
                      <CheckCircle2 className="h-4 w-4 text-green-600 mt-0.5 shrink-0" />
                    ) : (
                      <XCircle className="h-4 w-4 text-destructive mt-0.5 shrink-0" />
                    )}
                    <div className="flex-1 min-w-0">
                      <div className="font-medium">{r.label}</div>
                      {!r.ok && r.error && (
                        <div className="text-xs text-muted-foreground break-all">
                          {r.status} — {r.error}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
};

export default TestPushPage;
