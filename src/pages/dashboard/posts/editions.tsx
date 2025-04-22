
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

const AusgabenPage = () => {
  const [newAusgabe, setNewAusgabe] = useState('');
  const { editions, createEdition } = useEditions();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (newAusgabe.trim()) {
      createEdition(newAusgabe.trim());
      setNewAusgabe('');
    }
  };

  return (
    <DashboardLayout title="Ausgaben verwalten">
      <div className="grid gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Neue Ausgabe</CardTitle>
            <CardDescription>
              Erstellen Sie eine neue Ausgabe für Beiträge
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="flex gap-4">
              <Input
                placeholder="Ausgabenname (z.B. Jugendkompass 1/2024)"
                value={newAusgabe}
                onChange={(e) => setNewAusgabe(e.target.value)}
              />
              <Button type="submit">Erstellen</Button>
            </form>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Bestehende Ausgaben</CardTitle>
            <CardDescription>
              Liste aller verfügbaren Ausgaben
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

export default AusgabenPage;
