
import React from 'react';
import { useNavigate } from 'react-router-dom';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { usePosts } from '@/hooks/use-posts';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from '@/components/ui/table';
import { Switch } from '@/components/ui/switch';
import { PlusIcon, TrashIcon } from 'lucide-react';
import { AlertDialog, AlertDialogTrigger, AlertDialogContent, AlertDialogHeader, AlertDialogTitle, AlertDialogDescription, AlertDialogFooter, AlertDialogCancel, AlertDialogAction } from '@/components/ui/alert-dialog';
import { Badge } from '@/components/ui/badge';

const PostsPage = () => {
  const { posts, isLoading, deletePost, updatePostStatus } = usePosts();
  const navigate = useNavigate();

  const handleCreatePost = () => {
    navigate('/dashboard/posts/new');
  };

  const handleDelete = (id: string) => {
    deletePost(id);
  };

  const handleStatusChange = (contentId: string, currentStatus: 'draft' | 'published') => {
    const newStatus = currentStatus === 'draft' ? 'published' : 'draft';
    updatePostStatus({ contentId, status: newStatus });
  };

  return (
    <DashboardLayout title="Beiträge">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-semibold">Alle Beiträge</h2>
        <Button onClick={handleCreatePost}>
          <PlusIcon className="mr-2 h-4 w-4" />
          Neuer Beitrag
        </Button>
      </div>

      <Card className="shadow-sm">
        <CardHeader className="pb-2">
          <CardTitle>Beitragsliste</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex justify-center p-8">
              <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Titel</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Aktionen</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {posts.length > 0 ? (
                  posts.map((post) => (
                    <TableRow key={post.id}>
                      <TableCell className="font-medium">{post.title}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <Switch
                            checked={post.content.status === 'published'}
                            onCheckedChange={() => handleStatusChange(post.content_id!, post.content.status)}
                          />
                          <Badge variant={post.content.status === 'published' ? 'success' : 'secondary'}>
                            {post.content.status === 'published' ? 'Veröffentlicht' : 'Entwurf'}
                          </Badge>
                        </div>
                      </TableCell>
                      <TableCell>
                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button variant="outline" size="icon" className="text-destructive">
                              <TrashIcon className="h-4 w-4" />
                            </Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader>
                              <AlertDialogTitle>Beitrag löschen</AlertDialogTitle>
                              <AlertDialogDescription>
                                Möchten Sie diesen Beitrag wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.
                              </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel>Abbrechen</AlertDialogCancel>
                              <AlertDialogAction onClick={() => handleDelete(post.id)}>
                                Löschen
                              </AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={3} className="text-center py-6 text-muted-foreground">
                      Keine Beiträge gefunden
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </DashboardLayout>
  );
};

export default PostsPage;
