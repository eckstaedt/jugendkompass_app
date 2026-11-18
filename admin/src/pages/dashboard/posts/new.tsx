
import React from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { useForm } from 'react-hook-form';
import { useNavigate } from 'react-router-dom';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { usePosts, CreatePostParams } from '@/hooks/use-posts';
import { useAuth } from '@/contexts/AuthContext';
import { useCategories } from '@/hooks/use-categories';
import { useEditions } from '@/hooks/use-editions';
import { useToast } from '@/hooks/use-toast';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import RichTextEditor from '@/components/editor/RichTextEditor';
import { ImageUploader } from '@/components/posts/ImageUploader';
import { AudioUploader } from '@/components/posts/AudioUploader';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

const formSchema = z.object({
  title: z.string().min(1, 'Der Titel ist erforderlich'),
  body: z.string().min(1, 'Der Inhalt ist erforderlich'),
  category_id: z.string().min(1, 'Eine Kategorie ist erforderlich'),
  edition_id: z.string().min(1, 'Eine Ausgabe ist erforderlich'),
  status: z.enum(['published', 'draft']),
  image_url: z.string().min(1, 'Ein Bild ist erforderlich'),
});

type FormValues = z.infer<typeof formSchema>;

const NewPostPage = () => {
  const { createPost } = usePosts();
  const { user } = useAuth();
  const { categories, isLoading: categoriesLoading } = useCategories();
  const { editions, isLoading: editionsLoading } = useEditions();
  const { toast } = useToast();
  const navigate = useNavigate();
  const [audioFile, setAudioFile] = React.useState<File | null>(null);

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      title: '',
      body: '',
      category_id: '',
      edition_id: '',
      status: 'draft',
      image_url: '',
    },
  });

  const onSubmit = (data: FormValues) => {
    if (!data.image_url) {
      form.setError("image_url", { message: "Ein Bild ist erforderlich" });
      return;
    }

    const postData: CreatePostParams = {
      title: data.title,
      body: data.body,
      category_id: data.category_id,
      edition_id: data.edition_id,
      status: data.status,
      image_url: data.image_url,
      audioFile: audioFile,
      author_id: user?.id,
    };
    
    createPost(postData, {
      onSuccess: () => {
        toast({
          title: 'Erfolg',
          description: 'Beitrag wurde erfolgreich erstellt.',
          variant: 'success',
        });
        navigate('/dashboard/posts');
      },
      onError: (error) => {
        console.error('Failed to create post:', error);
        toast({
          title: 'Fehler',
          description: 'Der Beitrag konnte nicht erstellt werden.',
          variant: 'destructive',
        });
      },
    });
  };

  const isLoading = categoriesLoading || editionsLoading;

  return (
    <DashboardLayout title="Neuer Beitrag">
      <Card>
        <CardHeader>
          <CardTitle>Neuen Beitrag erstellen</CardTitle>
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
                        onChange={field.onChange}
                        required
                        label="Bild (JPEG, PNG, max. 3MB)*"
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="space-y-2">
                <FormLabel>Audio (optional)</FormLabel>
                <AudioUploader
                  currentAudio={null}
                  onFileSelected={(file) => setAudioFile(file)}
                />
                {audioFile && (
                  <p className="text-sm text-muted-foreground">
                    Ausgewählt: {audioFile.name}
                  </p>
                )}
              </div>

              <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                <FormField
                  control={form.control}
                  name="category_id"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Kategorie*</FormLabel>
                      <Select 
                        disabled={isLoading} 
                        onValueChange={field.onChange} 
                        value={field.value}
                      >
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Wählen Sie eine Kategorie" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {categories?.map((category) => (
                            <SelectItem key={category.id} value={category.id}>
                              {category.name}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="edition_id"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Ausgabe*</FormLabel>
                      <Select 
                        disabled={isLoading} 
                        onValueChange={field.onChange} 
                        value={field.value}
                      >
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Wählen Sie eine Ausgabe" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          {editions?.map((edition) => (
                            <SelectItem key={edition.id} value={edition.id}>
                              {edition.name}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <FormField
                control={form.control}
                name="status"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Status*</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value}>
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Wählen Sie einen Status" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        <SelectItem value="draft">Entwurf</SelectItem>
                        <SelectItem value="published">Veröffentlicht</SelectItem>
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="flex justify-end">
                <Button 
                  type="button" 
                  variant="outline" 
                  className="mr-2"
                  onClick={() => navigate('/dashboard/posts')}
                >
                  Abbrechen
                </Button>
                <Button type="submit">Beitrag erstellen</Button>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>
    </DashboardLayout>
  );
};

export default NewPostPage;
