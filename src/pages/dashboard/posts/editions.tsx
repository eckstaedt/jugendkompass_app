
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
import { Upload, FileText, ExternalLink, Pencil } from 'lucide-react';
import { BackfillButton } from '@/components/translations/BackfillButton';
import { RetranslateButton } from '@/components/translations/RetranslateButton';
import { TranslationStatusList } from '@/components/translations/TranslationStatusBadge';
import { useTranslationsForContents, summarizeLang, SUPPORTED_LANGS } from '@/hooks/use-translations';

const AusgabenPage = () => {
  const [name, setName] = useState('');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [releaseDate, setReleaseDate] = useState('');
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [pdfFile, setPdfFile] = useState<File | null>(null);
  const pdfInputRef = useRef<HTMLInputElement>(null);


  const [editingEdition, setEditingEdition] = useState<Edition | null>(null);
  const [editName, setEditName] = useState('');
  const [editTitle, setEditTitle] = useState('');
  const [editBody, setEditBody] = useState('');
  const [editImageUrl, setEditImageUrl] = useState<string | null>(null);
  const [editPdfFile, setEditPdfFile] = useState<File | null>(null);
  const [keepExistingPdf, setKeepExistingPdf] = useState(true);
  const editPdfInputRef = useRef<HTMLInputElement>(null);

  const { editions, createEdition, isCreating, updateEdition, isUpdating } = useEditions();
  const { data: translationsByContent } = useTranslationsForContents(editions.map((e) => e.content_id));
  const EXPECTED_FIELDS = ['title', 'body'];

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (name.trim()) {
      createEdition({
        name: name.trim(),
        title: title.trim() || undefined,
        body: body.trim() || undefined,
        image_url: imageUrl,
        pdfFile,
      });
      setName('');
      setTitle('');
      setBody('');
      setImageUrl(null);
      setPdfFile(null);
    }
  };

  const openEditDialog = (edition: Edition) => {
    setEditingEdition(edition);
    setEditName(edition.name);
    setEditTitle(edition.title || '');
    setEditBody(edition.body || '');
    setEditImageUrl(edition.image_url);
    setEditPdfFile(null);
    setKeepExistingPdf(!!edition.pdf_url);
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
                    {edition.body && <p className="text-sm text-muted-foreground mt-1 line-clamp-2">{edition.body}</p>}
                    {edition.pdf_url && (
                      <a href={edition.pdf_url} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 text-sm text-primary hover:underline mt-2">
                        <FileText className="h-3 w-3" />PDF anzeigen<ExternalLink className="h-3 w-3" />
                      </a>
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
