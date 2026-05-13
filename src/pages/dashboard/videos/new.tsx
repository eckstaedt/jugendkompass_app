import React, { useState } from 'react';
import { format } from 'date-fns';
import { CalendarIcon } from 'lucide-react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { useUploadVideo } from '@/hooks/use-videos';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { FileVideoIcon, LinkIcon, LoaderCircle, UploadIcon } from 'lucide-react';
import { ImageUploader } from '@/components/posts/ImageUploader';
import RichTextEditor from '@/components/editor/RichTextEditor';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Calendar } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { cn } from '@/lib/utils';

const NewVideoPage = () => {
  const { user } = useAuth();
  const uploadVideoMutation = useUploadVideo();
  const { toast } = useToast();

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [url, setUrl] = useState('');
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [createdAt, setCreatedAt] = useState<Date | undefined>(new Date());
  const [mode, setMode] = useState<'upload' | 'url'>('upload');
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

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

    const progressInterval = mode === 'upload'
      ? setInterval(() => {
          setUploadProgress(prev => (prev < 90 ? prev + 10 : prev));
        }, 500)
      : null;

    try {
      await uploadVideoMutation.mutateAsync({
        title,
        description,
        imageUrl: imageUrl!,
        ...(mode === 'upload' ? { file: file! } : { url }),
        userId: user.id,
        createdAt: createdAt ? createdAt.toISOString() : undefined,
      });

      setUploadProgress(100);
      setTitle('');
      setDescription('');
      setFile(null);
      setUrl('');
      setImageUrl(null);
      setCreatedAt(new Date());
      toast({
        title: "Video hinzugefügt",
        description: mode === 'upload'
          ? "Das Video wurde erfolgreich hochgeladen."
          : "Das Video wurde erfolgreich verlinkt.",
      });
    } catch (error) {
      console.error('Upload error:', error);
      toast({
        title: "Fehler",
        description: "Es gab einen Fehler beim Hinzufügen des Videos.",
        variant: "destructive"
      });
    } finally {
      if (progressInterval) clearInterval(progressInterval);
      setIsUploading(false);
      setUploadProgress(0);
    }
  };

  return (
    <DashboardLayout title="Neues Video hinzufügen">
      <div className="max-w-3xl mx-auto">
        <Card>
          <CardHeader>
            <CardTitle>Video-Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            <div>
              <label htmlFor="title" className="block text-sm font-medium mb-1">
                Video-Titel
              </label>
              <Input
                id="title"
                placeholder="Geben Sie einen Titel ein"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                disabled={isUploading}
              />
            </div>

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
                {file && (
                  <p className="text-sm text-muted-foreground">
                    Ausgewählte Datei: {file.name} ({(file.size / (1024 * 1024)).toFixed(2)} MB)
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

            <Button
              onClick={handleSubmit}
              disabled={isUploading || uploadVideoMutation.isPending || !isValid}
              className="w-full md:w-auto"
            >
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
      </div>
    </DashboardLayout>
  );
};

export default NewVideoPage;
