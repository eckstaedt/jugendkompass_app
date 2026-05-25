
import { useState, useRef } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { useEditions, Edition } from '@/hooks/use-editions';
import { ImageUploader } from '@/components/posts/ImageUploader';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle
} from '@/components/ui/card';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Upload, FileText, ExternalLink, Pencil, Send } from 'lucide-react';
import { BackfillButton } from '@/components/translations/BackfillButton';
import { RetranslateButton } from '@/components/translations/RetranslateButton';
import { TranslationStatusList } from '@/components/translations/TranslationStatusBadge';
import { useTranslationsForContents, summarizeLang, SUPPORTED_LANGS } from '@/hooks/use-translations';
import { useTestPushDevices, useSendTestPush } from '@/hooks/use-test-push-devices';
import { useToast } from '@/hooks/use-toast';

const toLocalInputValue = (iso: string) => {
  const d = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

const AusgabenPage = () => {
  const [name, setName] = useState('');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [publishedAt, setPublishedAt] = useState('');
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [pdfFile, setPdfFile] = useState<File | null>(null);
  const [notifTitle, setNotifTitle] = useState('');
  const [notifBody, setNotifBody] = useState('');
  const pdfInputRef = useRef<HTMLInputElement>(null);


  const [editingEdition, setEditingEdition] = useState<Edition | null>(null);
  const [editName, setEditName] = useState('');
  const [editTitle, setEditTitle] = useState('');
  const [editBody, setEditBody] = useState('');
  const [editPublishedAt, setEditPublishedAt] = useState('');
  const [editImageUrl, setEditImageUrl] = useState<string | null>(null);
  const [editPdfFile, setEditPdfFile] = useState<File | null>(null);
  const [editNotifTitle, setEditNotifTitle] = useState('');
  const [editNotifBody, setEditNotifBody] = useState('');
  const [keepExistingPdf, setKeepExistingPdf] = useState(true);
  const editPdfInputRef = useRef<HTMLInputElement>(null);


  const { editions, createEdition, isCreating, updateEdition, isUpdating } = useEditions();
  const { data: translationsByContent } = useTranslationsForContents(editions.map((e) => e.content_id));
  const { data: testDevices = [] } = useTestPushDevices();
  const { mutate: sendTestPush, isPending: isSendingTestPush } = useSendTestPush();
  const [pushingEditionId, setPushingEditionId] = useState<string | null>(null);
  const { toast } = useToast();
  const EXPECTED_FIELDS = ['title', 'body', 'notification_title', 'notification_body'];

  const handleSendTestPush = (edition: Edition) => {
    if (testDevices.length === 0) {
      toast({ title: 'Keine Test-Geräte', description: 'Bitte zuerst Test-Push-Geräte anlegen.', variant: 'destructive' });
      return;
    }
    const title = edition.notification_title?.trim() || edition.title?.trim() || edition.name;
    const body = edition.notification_body?.trim() || edition.body?.trim() || 'Neue Ausgabe verfügbar';
    setPushingEditionId(edition.id);
    sendTestPush(
      {
        device_ids: testDevices.map((d) => d.id),
        title,
        body,
        data: { type: 'edition', edition_id: edition.id, content_id: edition.content_id ?? '' },
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
        onSettled: () => setPushingEditionId(null),
      },
    );
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (name.trim()) {
      createEdition({
        name: name.trim(),
        title: title.trim() || undefined,
        body: body.trim() || undefined,
        image_url: imageUrl,
        pdfFile,
        published_at: publishedAt ? new Date(publishedAt).toISOString() : null,
        notification_title: notifTitle.trim() || null,
        notification_body: notifBody.trim() || null,
      });
      setName('');
      setTitle('');
      setBody('');
      setPublishedAt('');
      setImageUrl(null);
      setPdfFile(null);
      setNotifTitle('');
      setNotifBody('');
    }
  };

  const openEditDialog = (edition: Edition) => {
    setEditingEdition(edition);
    setEditName(edition.name);
    setEditTitle(edition.title || '');
    setEditBody(edition.body || '');
    setEditPublishedAt(edition.published_at ? toLocalInputValue(edition.published_at) : '');
    setEditImageUrl(edition.image_url);
    setEditPdfFile(null);
    setKeepExistingPdf(!!edition.pdf_url);
    setEditNotifTitle(edition.notification_title || '');
    setEditNotifBody(edition.notification_body || '');
  };

  const handleUpdate = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingEdition && editName.trim()) {
      updateEdition({
        id: editingEdition.id,
        name: editName.trim(),
        title: editTitle.trim() || undefined,
        body: editBody.trim() || undefined,
        image_url: editImageUrl,
        pdfFile: editPdfFile,
        keepExistingPdf,
        published_at: editPublishedAt ? new Date(editPublishedAt).toISOString() : null,
        notification_title: editNotifTitle.trim() || null,
        notification_body: editNotifBody.trim() || null,
      }, {
        onSuccess: () => setEditingEdition(null),
      });
    }
  };


  return (
    <DashboardLayout title="Ausgaben verwalten">
      <div className="grid gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Neue Ausgabe</CardTitle>
            <CardDescription>Erstellen Sie eine neue Ausgabe für Beiträge</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="grid gap-4">
              <div>
                <label className="block font-medium mb-1">Name *</label>
                <Input placeholder="Ausgabenname (z.B. Jugendkompass 1/2024)" value={name} onChange={(e) => setName(e.target.value)} required />
              </div>
              <div>
                <label className="block font-medium mb-1">Titel</label>
                <Input placeholder="Titel der Ausgabe" value={title} onChange={(e) => setTitle(e.target.value)} />
              </div>
              <div>
                <label className="block font-medium mb-1">Release-Datum & Uhrzeit</label>
                <Input type="datetime-local" value={publishedAt} onChange={(e) => setPublishedAt(e.target.value)} />
              </div>
              <div>
                <label className="block font-medium mb-1">Beschreibung</label>
                <Textarea placeholder="Beschreibung der Ausgabe..." value={body} onChange={(e) => setBody(e.target.value)} rows={4} />
              </div>

              <ImageUploader value={imageUrl} onChange={setImageUrl} label="Titelbild (JPEG, PNG, max. 3MB)" />
              <div>
                <label className="block font-medium mb-1">PDF-Dokument</label>
                <div className="flex gap-4 items-center">
                  <Button type="button" variant="outline" onClick={() => pdfInputRef.current?.click()}>
                    <Upload className="mr-2 h-4 w-4" />PDF auswählen
                  </Button>
                  <input type="file" accept="application/pdf" className="hidden" ref={pdfInputRef} onChange={(e) => setPdfFile(e.target.files?.[0] || null)} />
                  {pdfFile && (
                    <span className="text-sm text-muted-foreground flex items-center gap-1">
                      <FileText className="h-4 w-4" />
                      {pdfFile.name} ({(pdfFile.size / 1024 / 1024).toFixed(1)} MB)
                    </span>
                  )}
                </div>
              </div>
              <div className="rounded-lg border border-dashed p-3 grid gap-3">
                <p className="text-sm font-medium">Push-Benachrichtigung (optional)</p>
                <p className="text-xs text-muted-foreground">Wird automatisch zum Release-Zeitpunkt an alle App-Nutzer gesendet und übersetzt.</p>
                <div>
                  <label className="block text-sm font-medium mb-1">Push-Titel</label>
                  <Input placeholder="z.B. Neue Ausgabe ist da!" value={notifTitle} onChange={(e) => setNotifTitle(e.target.value)} />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1">Push-Text</label>
                  <Textarea placeholder="Kurzer Text für die Benachrichtigung..." value={notifBody} onChange={(e) => setNotifBody(e.target.value)} rows={2} />
                </div>
              </div>
              <Button type="submit" disabled={isCreating}>{isCreating ? 'Wird erstellt...' : 'Erstellen'}</Button>
            </form>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-start justify-between gap-4 space-y-0">
            <div>
              <CardTitle>Bestehende Ausgaben</CardTitle>
              <CardDescription>Liste aller verfügbaren Ausgaben</CardDescription>
            </div>
            <BackfillButton contentType="edition" invalidateKeys={['editions']} />
          </CardHeader>
          <CardContent>
            <div className="grid gap-4">
              {editions.map((edition) => {
                const byLang = edition.content_id ? translationsByContent?.[edition.content_id] : undefined;
                const statuses = Object.fromEntries(
                  SUPPORTED_LANGS.map((l) => [l, summarizeLang(byLang, l, EXPECTED_FIELDS)])
                );
                return (
                <div key={edition.id} className="flex items-start gap-4 rounded-lg border p-4">
                  {edition.image_url && (
                    <img src={edition.image_url} alt={edition.name} className="w-20 h-28 object-cover rounded border" />
                  )}
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold">{edition.name}</p>
                    {edition.title && <p className="text-sm text-muted-foreground">{edition.title}</p>}
                    {edition.published_at && (
                      <p className="text-xs text-muted-foreground mt-1">
                        Release: {new Date(edition.published_at).toLocaleString('de-DE', { dateStyle: 'medium', timeStyle: 'short' })}
                      </p>
                    )}
                    {edition.body && <p className="text-sm text-muted-foreground mt-1 line-clamp-2">{edition.body}</p>}
                    {edition.pdf_url && (
                      <a href={edition.pdf_url} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 text-sm text-primary hover:underline mt-2">
                        <FileText className="h-3 w-3" />PDF anzeigen<ExternalLink className="h-3 w-3" />
                      </a>
                    )}
                    {edition.notification_sent_at && (
                      <p className="text-xs text-muted-foreground mt-1">
                        Push gesendet: {new Date(edition.notification_sent_at).toLocaleString('de-DE', { dateStyle: 'medium', timeStyle: 'short' })}
                      </p>
                    )}

                    <div className="mt-2">
                      <TranslationStatusList statuses={statuses} />
                    </div>
                  </div>
                  <div className="flex flex-col gap-2 shrink-0">
                    <Button variant="outline" size="icon" onClick={() => openEditDialog(edition)}>
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <RetranslateButton contentId={edition.content_id} size="icon" />
                  </div>
                </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Edit Dialog */}
      <Dialog open={!!editingEdition} onOpenChange={(open) => !open && setEditingEdition(null)}>
        <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Ausgabe bearbeiten</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleUpdate} className="grid gap-4">
            <div>
              <label className="block font-medium mb-1">Name *</label>
              <Input value={editName} onChange={(e) => setEditName(e.target.value)} required />
            </div>
            <div>
              <label className="block font-medium mb-1">Titel</label>
              <Input value={editTitle} onChange={(e) => setEditTitle(e.target.value)} />
            </div>
            <div>
              <label className="block font-medium mb-1">Release-Datum & Uhrzeit</label>
              <Input type="datetime-local" value={editPublishedAt} onChange={(e) => setEditPublishedAt(e.target.value)} />
            </div>
            <div>
              <label className="block font-medium mb-1">Beschreibung</label>
              <Textarea value={editBody} onChange={(e) => setEditBody(e.target.value)} rows={4} />
            </div>

            <ImageUploader value={editImageUrl} onChange={setEditImageUrl} label="Titelbild (JPEG, PNG, max. 3MB)" />
            <div>
              <label className="block font-medium mb-1">PDF-Dokument</label>
              {keepExistingPdf && editingEdition?.pdf_url && !editPdfFile && (
                <div className="flex items-center gap-2 mb-2">
                  <a href={editingEdition.pdf_url} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 text-sm text-primary hover:underline">
                    <FileText className="h-3 w-3" />Aktuelles PDF<ExternalLink className="h-3 w-3" />
                  </a>
                  <Button type="button" variant="ghost" size="sm" className="text-destructive" onClick={() => setKeepExistingPdf(false)}>
                    Entfernen
                  </Button>
                </div>
              )}
              <div className="flex gap-4 items-center">
                <Button type="button" variant="outline" onClick={() => editPdfInputRef.current?.click()}>
                  <Upload className="mr-2 h-4 w-4" />{keepExistingPdf && editingEdition?.pdf_url ? 'PDF ersetzen' : 'PDF auswählen'}
                </Button>
                <input type="file" accept="application/pdf" className="hidden" ref={editPdfInputRef} onChange={(e) => {
                  const file = e.target.files?.[0] || null;
                  setEditPdfFile(file);
                  if (file) setKeepExistingPdf(false);
                }} />
                {editPdfFile && (
                  <span className="text-sm text-muted-foreground flex items-center gap-1">
                    <FileText className="h-4 w-4" />
                    {editPdfFile.name} ({(editPdfFile.size / 1024 / 1024).toFixed(1)} MB)
                  </span>
                )}
              </div>
            </div>
            <div className="rounded-lg border border-dashed p-3 grid gap-3">
              <p className="text-sm font-medium">Push-Benachrichtigung (optional)</p>
              {editingEdition?.notification_sent_at ? (
                <p className="text-xs text-muted-foreground">
                  Bereits gesendet am {new Date(editingEdition.notification_sent_at).toLocaleString('de-DE', { dateStyle: 'medium', timeStyle: 'short' })}.
                </p>
              ) : (
                <p className="text-xs text-muted-foreground">Wird automatisch zum Release-Zeitpunkt gesendet und übersetzt.</p>
              )}
              <div>
                <label className="block text-sm font-medium mb-1">Push-Titel</label>
                <Input value={editNotifTitle} onChange={(e) => setEditNotifTitle(e.target.value)} />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Push-Text</label>
                <Textarea value={editNotifBody} onChange={(e) => setEditNotifBody(e.target.value)} rows={2} />
              </div>
            </div>
            <div className="flex gap-2 justify-end">
              <Button type="button" variant="outline" onClick={() => setEditingEdition(null)}>Abbrechen</Button>
              <Button type="submit" disabled={isUpdating}>{isUpdating ? 'Wird gespeichert...' : 'Speichern'}</Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </DashboardLayout>
  );
};

export default AusgabenPage;
