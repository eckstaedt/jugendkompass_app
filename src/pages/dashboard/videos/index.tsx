import React, { useState, useRef, useEffect } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { useVideos, useUploadVideo, useDeleteVideo } from '@/hooks/use-videos';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { FileVideoIcon, LinkIcon, LoaderCircle, PencilIcon, Trash2Icon, UploadIcon } from 'lucide-react';
import { ImageUploader } from '@/components/posts/ImageUploader';
import { Progress } from '@/components/ui/progress';
import { format } from 'date-fns';
import { de } from 'date-fns/locale';
import RichTextEditor from '@/components/editor/RichTextEditor';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Video } from '@/lib/supabase';
import EditVideoDialog from '@/components/videos/EditVideoDialog';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { useTranslationsForContents, summarizeLang, SUPPORTED_LANGS } from '@/hooks/use-translations';
import { TranslationStatusList } from '@/components/translations/TranslationStatusBadge';

const VideosPage = () => {
  const { user } = useAuth();
  const { data: videos, isLoading } = useVideos();
  const { data: translationsMap } = useTranslationsForContents((videos ?? []).map((v: any) => v.content_id));
  const uploadVideoMutation = useUploadVideo();
  const deleteVideoMutation = useDeleteVideo();
  const { toast } = useToast();

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [url, setUrl] = useState('');
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [mode, setMode] = useState<'upload' | 'url'>('upload');
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const progressRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const [editVideo, setEditVideo] = useState<Video | null>(null);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [deleteVideoId, setDeleteVideoId] = useState<number | null>(null);

  useEffect(() => {
    return () => {
      if (progressRef.current) clearInterval(progressRef.current);
    };
  }, []);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = event.target.files?.[0];
    setFile(selectedFile || null);
  };

  const isValid = title && !!imageUrl && (mode === 'upload' ? !!file : !!url);

  const handleSubmit = async () => {
    if (!user || !isValid) {
      toast({
        title: "Fehler",
        description: "Bitte füllen Sie alle Pflichtfelder aus.",
        variant: "destructive"
      });
      return;
    }

    setIsUploading(true);
    setUploadProgress(0);

    if (mode === 'upload') {
      progressRef.current = setInterval(() => {
        setUploadProgress(prev => (prev < 90 ? prev + 10 : prev));
      }, 500);
    }

    try {
      await uploadVideoMutation.mutateAsync({
        title,
        description,
        imageUrl: imageUrl!,
        ...(mode === 'upload' ? { file: file! } : { url }),
        userId: user.id
      });

      setUploadProgress(100);
      setTitle('');
      setDescription('');
      setFile(null);
      setUrl('');
      setImageUrl(null);
      toast({
        title: "Video hinzugefügt",
        description: mode === 'upload'
          ? "Das Video wurde erfolgreich hochgeladen."
          : "Das Video wurde erfolgreich verlinkt.",
      });
    } catch (error) {
      toast({
        title: "Fehler",
        description: "Es gab einen Fehler beim Hinzufügen des Videos.",
        variant: "destructive"
      });
    } finally {
      if (progressRef.current) clearInterval(progressRef.current);
      setIsUploading(false);
      setUploadProgress(0);
    }
  };

  const handleDelete = async () => {
    if (deleteVideoId === null) return;
    try {
      await deleteVideoMutation.mutateAsync(deleteVideoId);
      toast({
        title: "Video gelöscht",
        description: "Das Video wurde erfolgreich gelöscht.",
      });
    } catch (error) {
      toast({
        title: "Fehler",
        description: "Das Video konnte nicht gelöscht werden.",
        variant: "destructive",
      });
    }
    setDeleteVideoId(null);
  };

  return (
    <DashboardLayout title="Videos">
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>Neues Video hinzufügen</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <Input
              placeholder="Video-Titel"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              disabled={isUploading}
            />
            <div>
              <label className="block text-sm font-medium mb-1">Beschreibung</label>
              <RichTextEditor content={description} onChange={setDescription} />
            </div>

            <ImageUploader
              value={imageUrl}
              onChange={setImageUrl}
              required
              label="Thumbnail (JPEG, PNG, max. 3MB)*"
            />

            <Tabs value={mode} onValueChange={(v) => setMode(v as 'upload' | 'url')}>
              <TabsList className="w-full">
                <TabsTrigger value="upload" className="flex-1 gap-2">
                  <UploadIcon className="h-4 w-4" />
                  Datei hochladen
                </TabsTrigger>
                <TabsTrigger value="url" className="flex-1 gap-2">
                  <LinkIcon className="h-4 w-4" />
                  URL angeben
                </TabsTrigger>
              </TabsList>
              <TabsContent value="upload" className="space-y-2 mt-4">
                <Input
                  type="file"
                  accept="video/*"
                  onChange={handleFileChange}
                  disabled={isUploading}
                />
                {file && !isUploading && (
                  <p className="text-sm text-muted-foreground">
                    Ausgewählt: {file.name} ({(file.size / (1024 * 1024)).toFixed(2)} MB)
                  </p>
                )}
              </TabsContent>
              <TabsContent value="url" className="mt-4">
                <Input
                  placeholder="https://www.youtube.com/watch?v=..."
                  value={url}
                  onChange={(e) => setUrl(e.target.value)}
                  disabled={isUploading}
                />
              </TabsContent>
            </Tabs>

            {isUploading && mode === 'upload' && (
              <div className="space-y-2">
                <Progress value={uploadProgress} className="w-full" />
                <p className="text-sm text-muted-foreground text-center">
                  Upload: {uploadProgress}%
                </p>
              </div>
            )}

            <Button onClick={handleSubmit} disabled={isUploading || !isValid}>
              {isUploading ? (
                <>
                  <LoaderCircle className="mr-2 h-4 w-4 animate-spin" />
                  {mode === 'upload' ? 'Wird hochgeladen...' : 'Wird gespeichert...'}
                </>
              ) : (
                <>
                  <FileVideoIcon className="mr-2 h-4 w-4" />
                  Video hinzufügen
                </>
              )}
            </Button>
          </CardContent>
        </Card>

        {/* Video List */}
        <Card>
          <CardHeader>
            <CardTitle>Videos</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div>Laden...</div>
            ) : videos?.length === 0 ? (
              <div>Keine Videos gefunden</div>
            ) : (
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {videos?.map((video) => (
                  <div
                    key={video.id}
                    className="border rounded-lg overflow-hidden shadow-sm"
                  >
                    {video.image_url && (
                      <img
                        src={video.image_url}
                        alt={video.title}
                        className="w-full h-40 object-cover"
                      />
                    )}
                    <div className="p-4 space-y-3">
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex items-center space-x-3 min-w-0">
                          <FileVideoIcon className="h-6 w-6 text-muted-foreground shrink-0" />
                          <div className="min-w-0">
                            <h3 className="font-semibold truncate">{video.title}</h3>
                            <p className="text-sm text-muted-foreground">
                              {video.created_at
                                ? format(new Date(video.created_at), 'dd. MMMM yyyy', { locale: de })
                                : 'Datum unbekannt'}
                            </p>
                          </div>
                        </div>
                        <div className="flex gap-1 shrink-0">
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => {
                              setEditVideo(video);
                              setEditDialogOpen(true);
                            }}
                          >
                            <PencilIcon className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => setDeleteVideoId(video.id)}
                          >
                            <Trash2Icon className="h-4 w-4 text-destructive" />
                          </Button>
                        </div>
                      </div>
                      {video.description && (
                        <div
                          className="text-sm text-muted-foreground line-clamp-2 prose prose-sm max-w-none"
                          dangerouslySetInnerHTML={{ __html: video.description }}
                        />
                      )}
                      <TranslationStatusList
                        statuses={Object.fromEntries(
                          SUPPORTED_LANGS.map((l) => [
                            l,
                            summarizeLang(translationsMap?.[video.content_id], l, ['title', 'description']),
                          ])
                        )}
                      />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      <EditVideoDialog
        video={editVideo}
        open={editDialogOpen}
        onOpenChange={setEditDialogOpen}
      />

      <AlertDialog open={deleteVideoId !== null} onOpenChange={(open) => !open && setDeleteVideoId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Video löschen</AlertDialogTitle>
            <AlertDialogDescription>
              Möchtest du dieses Video wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Abbrechen</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete}>Löschen</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </DashboardLayout>
  );
};

export default VideosPage;
