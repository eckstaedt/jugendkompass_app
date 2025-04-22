
import { useState } from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useEditions } from '@/hooks/use-editions';
import { 
  Card, 
  CardContent, 
  CardDescription, 
  CardHeader, 
  CardTitle 
} from '@/components/ui/card';

const EditionsPage = () => {
  const [newEdition, setNewEdition] = useState('');
  const { editions, createEdition } = useEditions();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (newEdition.trim()) {
      createEdition(newEdition.trim());
      setNewEdition('');
    }
  };

  return (
    <DashboardLayout title="Editionen verwalten">
      <div className="grid gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Neue Edition</CardTitle>
            <CardDescription>
              Erstellen Sie eine neue Edition für Beiträge
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="flex gap-4">
              <Input
                placeholder="Editionsname (z.B. Jugendkompass 1/2024)"
                value={newEdition}
                onChange={(e) => setNewEdition(e.target.value)}
              />
              <Button type="submit">Erstellen</Button>
            </form>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Bestehende Editionen</CardTitle>
            <CardDescription>
              Liste aller verfügbaren Editionen
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid gap-2">
              {editions.map((edition) => (
                <div
                  key={edition.id}
                  className="flex items-center justify-between rounded-lg border p-4"
                >
                  <span>{edition.name}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
};

export default EditionsPage;
