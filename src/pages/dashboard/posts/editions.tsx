
import { useState, useRef } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { useEditions } from '@/hooks/use-editions';
import { ImageUploader } from '@/components/posts/ImageUploader';
import { 
  Card, 
  CardContent, 
  CardDescription, 
  CardHeader, 
  CardTitle 
} from '@/components/ui/card';
import { Upload, FileText, ExternalLink } from 'lucide-react';

const AusgabenPage = () => {
  const [name, setName] = useState('');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [pdfFile, setPdfFile] = useState<File | null>(null);
  const pdfInputRef = useRef<HTMLInputElement>(null);
  const { editions, createEdition, isCreating } = useEditions();

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

  return (
    <DashboardLayout title="Ausgaben verwalten">
      <div className="grid gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Neue Ausgabe</CardTitle>
            <CardDescription>
              Erstellen Sie eine neue Ausgabe für Beiträge
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="grid gap-4">
              <div>
                <label className="block font-medium mb-1">Name *</label>
                <Input
                  placeholder="Ausgabenname (z.B. Jugendkompass 1/2024)"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                />
              </div>

              <div>
                <label className="block font-medium mb-1">Titel</label>
                <Input
                  placeholder="Titel der Ausgabe"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                />
              </div>

              <div>
                <label className="block font-medium mb-1">Beschreibung</label>
                <Textarea
                  placeholder="Beschreibung der Ausgabe..."
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  rows={4}
                />
              </div>

              <ImageUploader
                value={imageUrl}
                onChange={setImageUrl}
                label="Titelbild (JPEG, PNG, max. 3MB)"
              />

              <div>
                <label className="block font-medium mb-1">PDF-Dokument</label>
                <div className="flex gap-4 items-center">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => pdfInputRef.current?.click()}
                  >
                    <Upload className="mr-2 h-4 w-4" />
                    PDF auswählen
                  </Button>
                  <input
                    type="file"
                    accept="application/pdf"
                    className="hidden"
                    ref={pdfInputRef}
                    onChange={(e) => setPdfFile(e.target.files?.[0] || null)}
                  />
                  {pdfFile && (
                    <span className="text-sm text-muted-foreground flex items-center gap-1">
                      <FileText className="h-4 w-4" />
                      {pdfFile.name} ({(pdfFile.size / 1024 / 1024).toFixed(1)} MB)
                    </span>
                  )}
                </div>
              </div>

              <Button type="submit" disabled={isCreating}>
                {isCreating ? 'Wird erstellt...' : 'Erstellen'}
              </Button>
            </form>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Bestehende Ausgaben</CardTitle>
            <CardDescription>
              Liste aller verfügbaren Ausgaben
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4">
              {editions.map((edition) => (
                <div
                  key={edition.id}
                  className="flex items-start gap-4 rounded-lg border p-4"
                >
                  {edition.image_url && (
                    <img
                      src={edition.image_url}
                      alt={edition.name}
                      className="w-20 h-28 object-cover rounded border"
                    />
                  )}
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold">{edition.name}</p>
                    {edition.title && (
                      <p className="text-sm text-muted-foreground">{edition.title}</p>
                    )}
                    {edition.body && (
                      <p className="text-sm text-muted-foreground mt-1 line-clamp-2">{edition.body}</p>
                    )}
                    {edition.pdf_url && (
                      <a
                        href={edition.pdf_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-sm text-primary hover:underline mt-2"
                      >
                        <FileText className="h-3 w-3" />
                        PDF anzeigen
                        <ExternalLink className="h-3 w-3" />
                      </a>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
};

export default AusgabenPage;
