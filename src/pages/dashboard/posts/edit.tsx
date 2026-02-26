
import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { usePosts } from '@/hooks/use-posts';
import { useToast } from '@/hooks/use-toast';
import { useQueryClient } from '@tanstack/react-query';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import RichTextEditor from '@/components/editor/RichTextEditor';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { AudioUploader } from '@/components/posts/AudioUploader';
import { ImageUploader } from '@/components/posts/ImageUploader';
import { supabase } from '@/integrations/supabase/client';
import { AudioRecord } from '@/types/audio';

const formSchema = z.object({
  title: z.string().min(1, 'Der Titel ist erforderlich'),
  body: z.string().min(1, 'Der Inhalt ist erforderlich'),
  audio_file: z.any().optional(),
  image_url: z.string().min(1, 'Ein Bild ist erforderlich'),
});

type FormValues = z.infer<typeof formSchema>;

const EditPostPage = () => {
  const { id } = useParams<{ id: string }>();
  const { posts } = usePosts();
  const { toast } = useToast();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [currentAudio, setCurrentAudio] = useState<AudioRecord | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const post = posts.find(p => p.id === id);

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      title: post?.title || '',
      body: post?.body || '',
      image_url: post?.image_url || '',
    },
  });

  useEffect(() => {
    if (post) {
      // Update form values when post data is available
      form.setValue('title', post.title || '');
      form.setValue('body', post.body || '');
      form.setValue('image_url', post.image_url || '');
    }
  }, [post, form]);

  useEffect(() => {
    if (!post) {
      navigate('/dashboard/posts');
      return;
    }

    if (post.audio_id) {
      const fetchAudio = async () => {
        const { data: audio } = await supabase
          .from('audios')
          .select('*')
          .eq('id', post.audio_id)
          .single();
        
        if (audio) {
          setCurrentAudio(audio);
        }
      };
      
      fetchAudio();
    }
  }, [post, navigate]);

  const onSubmit = async (data: FormValues) => {
    if (!post) return;
    if (!data.image_url) {
      form.setError("image_url", { message: "Ein Bild ist erforderlich" });
      return;
    }

    try {
      setIsLoading(true);
      let audioId = post.audio_id;

      if (data.audio_file) {
        const file = data.audio_file;
        const fileExt = file.name.split('.').pop();
        const fileName = `${Math.random()}.${fileExt}`;
        const filePath = `${fileName}`;

        const { error: uploadError } = await supabase.storage
          .from('audios')
          .upload(filePath, file);

        if (uploadError) throw uploadError;

        const { data: publicUrlData } = supabase.storage
          .from('audios')
          .getPublicUrl(filePath);

        const { data: audioData, error: audioError } = await supabase
          .from('audios')
          .insert([
            { url: publicUrlData.publicUrl }
          ])
          .select()
          .single();

        if (audioError) throw audioError;
        
        audioId = audioData.id;
      }

      const { error: updateError } = await supabase
        .from('posts')
        .update({ 
          title: data.title, 
          body: data.body,
          audio_id: audioId,
          image_url: data.image_url
        })
        .eq('id', post.id);

      if (updateError) throw updateError;

      queryClient.invalidateQueries({ queryKey: ['posts'] });

      toast({
        title: "Erfolg",
        description: "Beitrag wurde aktualisiert",
        variant: "success",
      });

      navigate('/dashboard/posts');
    } catch (error) {
      console.error('Error updating post:', error);
      toast({
        title: "Fehler",
        description: `Beitrag konnte nicht aktualisiert werden: ${error instanceof Error ? error.message : 'Unbekannter Fehler'}`,
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  };

  if (!post) return null;

  return (
    <DashboardLayout title="Beitrag bearbeiten">
      <Card>
        <CardHeader>
          <CardTitle>Beitrag bearbeiten</CardTitle>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
              <FormField
                control={form.control}
                name="title"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Titel*</FormLabel>
                    <FormControl>
                      <Input placeholder="Geben Sie einen Titel ein" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="body"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Inhalt*</FormLabel>
                    <FormControl>
                      <RichTextEditor 
                        content={field.value} 
                        onChange={field.onChange}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="image_url"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Bild*</FormLabel>
                    <FormControl>
                      <ImageUploader
                        value={field.value}
                        onChange={(url) => {
                          console.log("Image URL updated:", url);
                          field.onChange(url);
                          form.setValue('image_url', url);
                        }}
                        required
                        label="Bild (JPEG, PNG, max. 3MB)*"
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="audio_file"
                render={({ field: { onChange, value, ...field } }) => (
                  <FormItem>
                    <FormLabel>Audio (MP3)</FormLabel>
                    <FormControl>
                      <AudioUploader
                        currentAudio={currentAudio}
                        onFileSelected={(file) => onChange(file)}
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="flex justify-end gap-4">
                <Button 
                  type="button" 
                  variant="outline"
                  onClick={() => navigate('/dashboard/posts')}
                  disabled={isLoading}
                >
                  Abbrechen
                </Button>
                <Button type="submit" disabled={isLoading}>
                  {isLoading ? 'Wird gespeichert...' : 'Speichern'}
                </Button>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>
    </DashboardLayout>
  );
};

export default EditPostPage;
