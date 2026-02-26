import React, { useState } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { useUploadVideo } from '@/hooks/use-videos';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { FileVideoIcon, LoaderCircle } from 'lucide-react';
import RichTextEditor from '@/components/editor/RichTextEditor';

const NewVideoPage = () => {
  const { user } = useAuth();
  const uploadVideoMutation = useUploadVideo();
  const { toast } = useToast();

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = event.target.files?.[0];
    setFile(selectedFile || null);
  };

  const handleUpload = async () => {
    if (!user || !file || !title) {
      toast({
        title: "Fehler",
        description: "Bitte geben Sie einen Titel und wählen Sie eine Datei aus.",
        variant: "destructive"
      });
      return;
    }

    setIsUploading(true);
    setUploadProgress(0);

    const simulateProgress = () => {
      setUploadProgress(prev => {
        if (prev < 90) {
          return prev + 10;
        }
        return prev;
      });
    };

    const progressInterval = setInterval(simulateProgress, 500);

    try {
      await uploadVideoMutation.mutateAsync({ 
        title,
        description,
        file, 
        userId: user.id 
      });

      setUploadProgress(100);
      setTitle('');
      setDescription('');
      setFile(null);

      toast({
        title: "Video hochgeladen",
        description: "Das Video wurde erfolgreich hochgeladen.",
      });
    } catch (error) {
      console.error('Upload error:', error);
      toast({
        title: "Fehler",
        description: "Es gab einen Fehler beim Hochladen des Videos. Bitte prüfen Sie die Konsole für weitere Details.",
        variant: "destructive"
      });
    } finally {
      clearInterval(progressInterval);
      setIsUploading(false);
      setUploadProgress(0);
    }
  };

  return (
    <DashboardLayout title="Neues Video hochladen">
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

            <div>
              <label htmlFor="video-file" className="block text-sm font-medium mb-1">
                Video-Datei
              </label>
              <Input 
                id="video-file"
                type="file" 
                accept="video/*"
                onChange={handleFileChange}
                disabled={isUploading}
              />
              {file && (
                <p className="mt-2 text-sm text-muted-foreground">
                  Ausgewählte Datei: {file.name} ({(file.size / (1024 * 1024)).toFixed(2)} MB)
                </p>
              )}
            </div>

            {isUploading && (
              <div className="space-y-2">
                <Progress value={uploadProgress} className="w-full" />
                <p className="text-sm text-muted-foreground text-center">
                  Upload: {uploadProgress}%
                </p>
              </div>
            )}

            <Button 
              onClick={handleUpload} 
              disabled={isUploading || uploadVideoMutation.isPending || !title || !file}
              className="w-full md:w-auto"
            >
              {isUploading ? (
                <>
                  <LoaderCircle className="mr-2 h-4 w-4 animate-spin" />
                  Wird hochgeladen...
                </>
              ) : (
                <>
                  <FileVideoIcon className="mr-2 h-4 w-4" />
                  Video hochladen
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
