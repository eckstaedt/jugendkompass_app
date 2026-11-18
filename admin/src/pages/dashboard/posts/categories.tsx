
import { useState } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useCategories } from '@/hooks/use-categories';
import { 
  Card, 
  CardContent, 
  CardDescription, 
  CardHeader, 
  CardTitle 
} from '@/components/ui/card';

const CategoriesPage = () => {
  const [newCategory, setNewCategory] = useState('');
  const { categories, createCategory } = useCategories();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (newCategory.trim()) {
      createCategory(newCategory.trim());
      setNewCategory('');
    }
  };

  return (
    <DashboardLayout title="Kategorien verwalten">
      <div className="grid gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Neue Kategorie</CardTitle>
            <CardDescription>
              Erstellen Sie eine neue Kategorie für Beiträge
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="flex gap-4">
              <Input
                placeholder="Kategoriename"
                value={newCategory}
                onChange={(e) => setNewCategory(e.target.value)}
              />
              <Button type="submit">Erstellen</Button>
            </form>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Bestehende Kategorien</CardTitle>
            <CardDescription>
              Liste aller verfügbaren Kategorien
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid gap-2">
              {categories.map((category) => (
                <div
                  key={category.id}
                  className="flex items-center justify-between rounded-lg border p-4"
                >
                  <span>{category.name}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
};

export default CategoriesPage;
