import { useEffect, useMemo, useState } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import {
  Announcement,
  AnnouncementInput,
  AnnouncementStatus,
  announcementStatus,
  useAnnouncements,
  useDeleteAnnouncement,
  useSaveAnnouncement,
  useSetAnnouncementActive,
} from '@/hooks/use-announcements';
import { Pencil, Plus, Trash2, X } from 'lucide-react';

/** Date → value for <input type="datetime-local"> (local time). */
function toLocalInput(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleString('de-DE', { dateStyle: 'medium', timeStyle: 'short' });
}

const STATUS_LABEL: Record<AnnouncementStatus, string> = {
  live: 'Wird angezeigt',
  scheduled: 'Geplant',
  expired: 'Abgelaufen',
  inactive: 'Deaktiviert',
};

const STATUS_CLASS: Record<AnnouncementStatus, string> = {
  live: 'bg-green-600 hover:bg-green-600 text-white',
  scheduled: 'bg-blue-600 hover:bg-blue-600 text-white',
  expired: 'bg-muted text-muted-foreground hover:bg-muted',
  inactive: 'bg-muted text-muted-foreground hover:bg-muted',
};

interface FormState {
  title: string;
  message: string;
  startsAt: string;
  endsAt: string;
  isActive: boolean;
  dismissible: boolean;
  showOnce: boolean;
  imageFile?: File;
  existingImageUrl: string | null;
  removeImage: boolean;
}

function emptyForm(): FormState {
  const now = new Date();
  return {
    title: '',
    message: '',
    startsAt: toLocalInput(now),
    endsAt: toLocalInput(new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)),
    isActive: true,
    dismissible: true,
    showOnce: true,
    existingImageUrl: null,
    removeImage: false,
  };
}

function formFrom(a: Announcement): FormState {
  return {
    title: a.title,
    message: a.message,
    startsAt: toLocalInput(new Date(a.starts_at)),
    endsAt: toLocalInput(new Date(a.ends_at)),
    isActive: a.is_active,
    dismissible: a.dismissible,
    showOnce: a.show_once,
    existingImageUrl: a.image_url,
    removeImage: false,
  };
}

/** Rough phone preview of the full-screen popup in the app. */
const PopupPreview = ({ form, imageUrl }: { form: FormState; imageUrl: string | null }) => (
  <div className="mx-auto w-[260px] rounded-[2rem] border-4 border-foreground/80 bg-background p-4 shadow-lg">
    <div className="relative flex min-h-[420px] flex-col items-center justify-center gap-4 text-center">
      {form.dismissible && <X className="absolute right-0 top-0 h-5 w-5 text-foreground" />}
      {imageUrl && (
        <img src={imageUrl} alt="" className="max-h-[180px] max-w-full rounded-2xl object-contain" />
      )}
      <div className="text-lg font-bold leading-snug">{form.title || 'Titel'}</div>
      <div className="whitespace-pre-line text-sm text-muted-foreground">{form.message || 'Text des Popups'}</div>
      {form.dismissible && (
        <div className="mt-2 w-full rounded-full bg-red-600 py-2 text-sm font-semibold text-white">Verstanden</div>
      )}
    </div>
  </div>
);

const AnnouncementsPage = () => {
  const { data: announcements, isLoading, error } = useAnnouncements();
  const save = useSaveAnnouncement();
  const setActive = useSetAnnouncementActive();
  const remove = useDeleteAnnouncement();
  const { toast } = useToast();

  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);

  const localPreviewUrl = useMemo(
    () => (form.imageFile ? URL.createObjectURL(form.imageFile) : null),
    [form.imageFile],
  );
  useEffect(() => () => {
    if (localPreviewUrl) URL.revokeObjectURL(localPreviewUrl);
  }, [localPreviewUrl]);
  const previewImage = localPreviewUrl ?? (form.removeImage ? null : form.existingImageUrl);

  const update = (patch: Partial<FormState>) => setForm((f) => ({ ...f, ...patch }));

  const resetForm = () => {
    setEditingId(null);
    setForm(emptyForm());
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim() || !form.message.trim()) {
      toast({ title: 'Fehler', description: 'Titel und Text sind erforderlich.', variant: 'destructive' });
      return;
    }
    const startsAt = new Date(form.startsAt);
    const endsAt = new Date(form.endsAt);
    if (isNaN(startsAt.getTime()) || isNaN(endsAt.getTime()) || endsAt <= startsAt) {
      toast({ title: 'Fehler', description: 'Das Ende muss nach dem Start liegen.', variant: 'destructive' });
      return;
    }
    const input: AnnouncementInput = {
      title: form.title,
      message: form.message,
      starts_at: startsAt.toISOString(),
      ends_at: endsAt.toISOString(),
      is_active: form.isActive,
      dismissible: form.dismissible,
      show_once: form.showOnce,
      imageFile: form.imageFile,
      removeImage: form.removeImage,
    };
    try {
      await save.mutateAsync({ id: editingId ?? undefined, input });
      toast({
        title: 'Gespeichert',
        description: editingId
          ? 'Das Popup wurde aktualisiert. Die Übersetzungen werden automatisch erneuert.'
          : 'Das Popup wurde erstellt und wird automatisch übersetzt.',
      });
      resetForm();
    } catch (err) {
      toast({
        title: 'Fehler beim Speichern',
        description: err instanceof Error ? err.message : String(err),
        variant: 'destructive',
      });
    }
  };

  const handleDelete = async (a: Announcement) => {
    if (!window.confirm(`Popup „${a.title}“ wirklich löschen?`)) return;
    try {
      await remove.mutateAsync(a.id);
      if (editingId === a.id) resetForm();
      toast({ title: 'Gelöscht', description: 'Das Popup wurde gelöscht.' });
    } catch (err) {
      toast({
        title: 'Fehler beim Löschen',
        description: err instanceof Error ? err.message : String(err),
        variant: 'destructive',
      });
    }
  };

  const handleToggle = async (a: Announcement, isActive: boolean) => {
    try {
      await setActive.mutateAsync({ id: a.id, is_active: isActive });
    } catch (err) {
      toast({
        title: 'Fehler',
        description: err instanceof Error ? err.message : String(err),
        variant: 'destructive',
      });
    }
  };

  return (
    <DashboardLayout title="Popups">
      <div className="mx-auto max-w-5xl space-y-8">
        <div className="rounded-lg border bg-card p-6">
          <div className="mb-1 flex items-center justify-between">
            <h2 className="text-lg font-semibold">{editingId ? 'Popup bearbeiten' : 'Neues Popup'}</h2>
            {editingId && (
              <Button variant="ghost" size="sm" onClick={resetForm} type="button">
                Abbrechen
              </Button>
            )}
          </div>
          <p className="mb-6 text-sm text-muted-foreground">
            Das Popup erscheint in der App als Vollbild beim Öffnen – im gewählten Zeitraum. Auf Deutsch
            schreiben, die anderen Sprachen werden automatisch übersetzt.
          </p>

          <div className="grid gap-8 md:grid-cols-[1fr_auto]">
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="ann-title">Titel</Label>
                <Input
                  id="ann-title"
                  value={form.title}
                  onChange={(e) => update({ title: e.target.value })}
                  placeholder="z. B. Neue Ausgabe ist da!"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="ann-message">Text</Label>
                <Textarea
                  id="ann-message"
                  value={form.message}
                  onChange={(e) => update({ message: e.target.value })}
                  placeholder="Was sollen die Nutzer erfahren?"
                  rows={5}
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="ann-image">Bild (optional)</Label>
                <div className="flex items-center gap-3">
                  <Input
                    id="ann-image"
                    type="file"
                    accept="image/*"
                    onChange={(e) => update({ imageFile: e.target.files?.[0], removeImage: false })}
                  />
                  {(previewImage || form.imageFile) && (
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={() => update({ imageFile: undefined, removeImage: true })}
                    >
                      Bild entfernen
                    </Button>
                  )}
                </div>
                <p className="text-xs text-muted-foreground">
                  Wird im Originalformat angezeigt (nicht beschnitten).
                </p>
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="ann-start">Anzeigen ab</Label>
                  <Input
                    id="ann-start"
                    type="datetime-local"
                    value={form.startsAt}
                    onChange={(e) => update({ startsAt: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="ann-end">Anzeigen bis</Label>
                  <Input
                    id="ann-end"
                    type="datetime-local"
                    value={form.endsAt}
                    onChange={(e) => update({ endsAt: e.target.value })}
                  />
                </div>
              </div>

              <div className="space-y-3 rounded-md border p-4">
                <label className="flex items-center justify-between gap-4">
                  <span>
                    <span className="block text-sm font-medium">Aktiv</span>
                    <span className="block text-xs text-muted-foreground">Ausgeschaltet wird es nie angezeigt.</span>
                  </span>
                  <Switch checked={form.isActive} onCheckedChange={(v) => update({ isActive: v })} />
                </label>
                <label className="flex items-center justify-between gap-4">
                  <span>
                    <span className="block text-sm font-medium">Nur einmal pro Gerät</span>
                    <span className="block text-xs text-muted-foreground">
                      Nach dem Schließen nicht erneut zeigen.
                    </span>
                  </span>
                  <Switch checked={form.showOnce} onCheckedChange={(v) => update({ showOnce: v })} />
                </label>
                <label className="flex items-center justify-between gap-4">
                  <span>
                    <span className="block text-sm font-medium">Schließbar</span>
                    <span className="block text-xs text-muted-foreground">
                      Aus = Nutzer können die App im Zeitraum nicht benutzen (z. B. Wartung).
                    </span>
                  </span>
                  <Switch checked={form.dismissible} onCheckedChange={(v) => update({ dismissible: v })} />
                </label>
              </div>

              <Button type="submit" disabled={save.isPending}>
                <Plus className="mr-2 h-4 w-4" />
                {save.isPending ? 'Wird gespeichert…' : editingId ? 'Änderungen speichern' : 'Popup erstellen'}
              </Button>
            </form>

            <div>
              <div className="mb-2 text-center text-xs font-medium uppercase tracking-wide text-muted-foreground">
                Vorschau
              </div>
              <PopupPreview form={form} imageUrl={previewImage} />
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <h2 className="text-lg font-semibold">Alle Popups</h2>
          {isLoading && <div>Lädt…</div>}
          {error && (
            <div className="text-sm text-destructive">
              Popups konnten nicht geladen werden: {error instanceof Error ? error.message : String(error)}
            </div>
          )}
          {!isLoading && !error && (announcements?.length ?? 0) === 0 && (
            <div className="text-sm text-muted-foreground">Noch keine Popups.</div>
          )}
          {announcements?.map((a) => {
            const status = announcementStatus(a);
            return (
              <div key={a.id} className="flex gap-4 rounded-lg border bg-card p-4">
                {a.image_url && (
                  <img src={a.image_url} alt="" className="h-20 w-20 flex-shrink-0 rounded-md object-contain bg-muted" />
                )}
                <div className="min-w-0 flex-1 space-y-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="font-semibold">{a.title}</span>
                    <Badge className={STATUS_CLASS[status]}>{STATUS_LABEL[status]}</Badge>
                    {a.show_once && <Badge variant="outline">einmal</Badge>}
                    {!a.dismissible && <Badge variant="destructive">nicht schließbar</Badge>}
                  </div>
                  <p className="line-clamp-2 whitespace-pre-line text-sm text-muted-foreground">{a.message}</p>
                  <p className="text-xs text-muted-foreground">
                    {formatDate(a.starts_at)} – {formatDate(a.ends_at)}
                  </p>
                </div>
                <div className="flex flex-shrink-0 flex-col items-end gap-2">
                  <Switch
                    checked={a.is_active}
                    onCheckedChange={(v) => handleToggle(a, v)}
                    aria-label="Aktiv"
                  />
                  <div className="flex gap-1">
                    <Button
                      variant="ghost"
                      size="icon"
                      title="Bearbeiten"
                      onClick={() => {
                        setEditingId(a.id);
                        setForm(formFrom(a));
                        window.scrollTo({ top: 0, behavior: 'smooth' });
                      }}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button variant="ghost" size="icon" title="Löschen" onClick={() => handleDelete(a)}>
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </DashboardLayout>
  );
};

export default AnnouncementsPage;
