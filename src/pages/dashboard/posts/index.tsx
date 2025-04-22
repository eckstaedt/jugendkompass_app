
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { PlusIcon, SearchIcon, Edit2Icon, Trash2Icon, EyeIcon } from 'lucide-react';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Badge } from '@/components/ui/badge';

// Beispieldaten für Beiträge
const mockPosts = [
  {
    id: '1',
    title: 'Gottes Plan für dein Leben',
    category: 'Glaube',
    edition: 'Jugendkompass 1/2023',
    published: true,
    created_at: '2023-01-15T10:30:00',
  },
  {
    id: '2',
    title: 'Wie du deinen Glauben im Alltag leben kannst',
    category: 'Praxis',
    edition: 'Jugendkompass 1/2023',
    published: true,
    created_at: '2023-01-20T14:45:00',
  },
  {
    id: '3',
    title: 'Die Kraft des Gebets',
    category: 'Glaube',
    edition: 'Jugendkompass 2/2023',
    published: true,
    created_at: '2023-04-10T09:15:00',
  },
  {
    id: '4',
    title: 'Gemeinschaft unter Christen',
    category: 'Gemeinschaft',
    edition: 'Jugendkompass 2/2023',
    published: false,
    created_at: '2023-04-18T16:20:00',
  },
  {
    id: '5',
    title: 'Bibelstudium für Anfänger',
    category: 'Bibel',
    edition: 'Jugendkompass 3/2023',
    published: true,
    created_at: '2023-07-05T11:10:00',
  },
];

const PostsPage = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const navigate = useNavigate();
  
  // Beiträge filtern basierend auf dem Suchbegriff
  const filteredPosts = mockPosts.filter(
    (post) =>
      post.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      post.category.toLowerCase().includes(searchTerm.toLowerCase()) ||
      post.edition.toLowerCase().includes(searchTerm.toLowerCase())
  );
  
  // Datum formatieren
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('de-DE', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    }).format(date);
  };
  
  return (
    <DashboardLayout title="Beiträge verwalten">
      <div className="mb-6 flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div className="relative w-full md:w-96">
          <SearchIcon className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Beiträge suchen..."
            className="pl-9"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <Button onClick={() => navigate('/dashboard/posts/new')}>
          <PlusIcon className="mr-2 h-4 w-4" />
          Neuer Beitrag
        </Button>
      </div>
      
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-[300px]">Titel</TableHead>
              <TableHead>Kategorie</TableHead>
              <TableHead>Edition</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Erstellt am</TableHead>
              <TableHead className="text-right">Aktionen</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredPosts.length > 0 ? (
              filteredPosts.map((post) => (
                <TableRow key={post.id}>
                  <TableCell className="font-medium">{post.title}</TableCell>
                  <TableCell>{post.category}</TableCell>
                  <TableCell>{post.edition}</TableCell>
                  <TableCell>
                    <Badge
                      variant={post.published ? "success" : "warning"}
                      className="capitalize"
                    >
                      {post.published ? "Veröffentlicht" : "Entwurf"}
                    </Badge>
                  </TableCell>
                  <TableCell>{formatDate(post.created_at)}</TableCell>
                  <TableCell className="text-right">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon">
                          <span className="sr-only">Menü öffnen</span>
                          <EyeIcon className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem
                          onClick={() => navigate(`/dashboard/posts/${post.id}`)}
                        >
                          <EyeIcon className="mr-2 h-4 w-4" />
                          Ansehen
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          onClick={() => navigate(`/dashboard/posts/${post.id}/edit`)}
                        >
                          <Edit2Icon className="mr-2 h-4 w-4" />
                          Bearbeiten
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          className="text-destructive focus:bg-destructive focus:text-destructive-foreground"
                          onClick={() => {
                            if (confirm('Diesen Beitrag wirklich löschen?')) {
                              // Hier würde die Löschlogik implementiert werden
                              console.log(`Beitrag ${post.id} löschen`);
                            }
                          }}
                        >
                          <Trash2Icon className="mr-2 h-4 w-4" />
                          Löschen
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={6} className="h-24 text-center">
                  Keine Beiträge gefunden.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
    </DashboardLayout>
  );
};

export default PostsPage;
