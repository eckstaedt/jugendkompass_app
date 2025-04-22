
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
import { usePosts } from '@/hooks/use-posts';
import { useCategories } from '@/hooks/use-categories';
import { useEditions } from '@/hooks/use-editions';

const PostsPage = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const navigate = useNavigate();
  const { posts, isLoading: isLoadingPosts, deletePost } = usePosts();
  const { categories } = useCategories();
  const { editions } = useEditions();
  
  // Filter posts based on search term
  const filteredPosts = posts.filter(
    (post) =>
      post.title.toLowerCase().includes(searchTerm.toLowerCase())
  );
  
  // Format date
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('de-DE', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    }).format(date);
  };

  // Find category and edition names
  const getCategoryName = (categoryId: string | null) => {
    if (!categoryId) return '-';
    return categories.find(cat => cat.id === categoryId)?.name || '-';
  };

  const getEditionName = (editionId: string | null) => {
    if (!editionId) return '-';
    return editions.find(ed => ed.id === editionId)?.name || '-';
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
              <TableHead>Erstellt am</TableHead>
              <TableHead className="text-right">Aktionen</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoadingPosts ? (
              <TableRow>
                <TableCell colSpan={5} className="h-24 text-center">
                  Lädt...
                </TableCell>
              </TableRow>
            ) : filteredPosts.length > 0 ? (
              filteredPosts.map((post) => (
                <TableRow key={post.id}>
                  <TableCell className="font-medium">{post.title}</TableCell>
                  <TableCell>{getCategoryName(post.category_id)}</TableCell>
                  <TableCell>{getEditionName(post.edition_id)}</TableCell>
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
                              deletePost(post.id);
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
                <TableCell colSpan={5} className="h-24 text-center">
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
