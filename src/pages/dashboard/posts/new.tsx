
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { 
  Select, 
  SelectContent, 
  SelectItem, 
  SelectTrigger, 
  SelectValue 
} from '@/components/ui/select';
import { useCategories } from '@/hooks/use-categories';
import { useEditions } from '@/hooks/use-editions';
import { usePosts } from '@/hooks/use-posts';
import { useToast } from '@/hooks/use-toast';

const NewPostPage = () => {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [editionId, setEditionId] = useState('');
  const [status, setStatus] = useState('draft');

  const { categories } = useCategories();
  const { editions } = useEditions();
  const { createPost } = usePosts();
  const { toast } = useToast();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!title.trim()) {
      toast({
        title: 'Fehler',
        description: 'Bitte geben Sie einen Titel ein',
        variant: 'destructive'
      });
      return;
    }

    try {
      await createPost({
        title,
        body,
        category_id: categoryId || null,
        edition_id: editionId || null,
        status
      });

      toast({
        title: 'Erfolg',
        description: 'Beitrag wurde erstellt',
        variant: 'success'
      });

      navigate('/dashboard/posts');
    } catch (error) {
      toast({
        title: 'Fehler',
        description: 'Beitrag konnte nicht erstellt werden',
        variant: 'destructive'
      });
    }
  };

  return (
    <DashboardLayout title="Neuer Beitrag">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="title" className="block mb-2">Titel</label>
          <Input
            id="title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Titel des Beitrags"
            required
          />
        </div>

        <div>
          <label htmlFor="body" className="block mb-2">Inhalt</label>
          <Textarea
            id="body"
            value={body}
            onChange={(e) => setBody(e.target.value)}
            placeholder="Beitrag schreiben..."
            rows={10}
          />
        </div>

        <div className="grid md:grid-cols-2 gap-4">
          <div>
            <label htmlFor="category" className="block mb-2">Kategorie</label>
            <Select 
              value={categoryId} 
              onValueChange={setCategoryId}
            >
              <SelectTrigger>
                <SelectValue placeholder="Kategorie wählen" />
              </SelectTrigger>
              <SelectContent>
                {categories.map((category) => (
                  <SelectItem 
                    key={category.id} 
                    value={category.id}
                  >
                    {category.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div>
            <label htmlFor="edition" className="block mb-2">Ausgabe</label>
            <Select 
              value={editionId} 
              onValueChange={setEditionId}
            >
              <SelectTrigger>
                <SelectValue placeholder="Ausgabe wählen" />
              </SelectTrigger>
              <SelectContent>
                {editions.map((edition) => (
                  <SelectItem 
                    key={edition.id} 
                    value={edition.id}
                  >
                    {edition.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>

        <div>
          <label htmlFor="status" className="block mb-2">Status</label>
          <Select 
            value={status} 
            onValueChange={setStatus}
          >
            <SelectTrigger>
              <SelectValue placeholder="Status wählen" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="draft">Entwurf</SelectItem>
              <SelectItem value="active">Aktiv</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="flex justify-end space-x-4">
          <Button type="button" variant="outline" onClick={() => navigate('/dashboard/posts')}>
            Abbrechen
          </Button>
          <Button type="submit">Beitrag erstellen</Button>
        </div>
      </form>
    </DashboardLayout>
  );
};

export default NewPostPage;
