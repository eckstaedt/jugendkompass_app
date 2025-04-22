
import React, { useState } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { useVideos, useUploadVideo } from '@/hooks/use-videos';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { FileVideoIcon } from 'lucide-react';
import { format } from 'date-fns';
import { de } from 'date-fns/locale';

const VideosPage = () => {
  const { user } = useAuth();
  const { data: videos, isLoading } = useVideos();
  const uploadVideoMutation = useUploadVideo();
  const { toast } = useToast();

  const [title, setTitle] = useState('');
  const [file, setFile] = useState<File | null>(null);

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

    try {
      await uploadVideoMutation.mutateAsync({ 
        title, 
        file, 
        userId: user.id 
      });

      setTitle('');
      setFile(null);

      toast({
        title: "Video hochgeladen",
        description: "Das Video wurde erfolgreich hochgeladen.",
      });
    } catch (error) {
      toast({
        title: "Fehler",
        description: "Es gab einen Fehler beim Hochladen des Videos.",
        variant: "destructive"
      });
    }
  };

  return (
    <DashboardLayout title="Videos">
      <div className="space-y-6">
        {/* Video Upload Section */}
        <Card>
          <CardHeader>
            <CardTitle>Neues Video hochladen</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <Input 
              placeholder="Video-Titel" 
              value={title}
              onChange={(e) => setTitle(e.target.value)}
            />
            <Input 
              type="file" 
              accept="video/*"
              onChange={handleFileChange}
            />
            <Button onClick={handleUpload} disabled={uploadVideoMutation.isPending}>
              Video hochladen
            </Button>
          </CardContent>
        </Card>

        {/* Video List */}
        <Card>
          <CardHeader>
            <CardTitle>Hochgeladene Videos</CardTitle>
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
                    <div className="p-4 flex items-center space-x-4">
                      <FileVideoIcon className="h-8 w-8 text-muted-foreground" />
                      <div>
                        <h3 className="font-semibold">{video.title}</h3>
                        <p className="text-sm text-muted-foreground">
                          {video.created_at 
                            ? format(new Date(video.created_at), 'dd. MMMM yyyy', { locale: de }) 
                            : 'Datum unbekannt'}
                        </p>
                      </div>
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

export default VideosPage;
