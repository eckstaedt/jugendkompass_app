
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { usePosts } from '@/hooks/use-posts';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from '@/components/ui/table';
import { Switch } from '@/components/ui/switch';
import { PlusIcon, TrashIcon, PencilIcon, Upload } from 'lucide-react';
import { AlertDialog, AlertDialogTrigger, AlertDialogContent, AlertDialogHeader, AlertDialogTitle, AlertDialogDescription, AlertDialogFooter, AlertDialogCancel, AlertDialogAction } from '@/components/ui/alert-dialog';
import { Badge } from '@/components/ui/badge';
import { useAuth } from '@/contexts/AuthContext';
import { BulkPostDialog } from '@/components/posts/BulkPostDialog';
import { useBulkCreatePosts } from '@/hooks/posts/use-bulk-create-posts';

const PostsPage = () => {
  const { posts, isLoading, deletePost, updatePostStatus } = usePosts();
  const [bulkOpen, setBulkOpen] = useState(false);
  const bulkCreate = useBulkCreatePosts();
  const navigate = useNavigate();
  const { user } = useAuth();

  const handleCreatePost = () => {
    navigate('/dashboard/posts/new');
  };

  const handleDelete = (id: string) => {
    deletePost(id);
  };

  const handleStatusChange = (postId: string, contentId: string, currentStatus: string | undefined) => {
    if (!user?.id) {
      console.error('Cannot update status: No user ID available');
      return;
    }
    
    const status = currentStatus === 'published' ? 'draft' : 'published';
    
    console.log('Toggling status:', { postId, currentStatus, newStatus: status });
    updatePostStatus({ 
      id: postId, 
      status, 
      userId: user.id 
    });
  };

  const handleEditPost = (id: string) => {
    navigate(`/dashboard/posts/edit/${id}`);
  };

  return (
    <DashboardLayout title="Beiträge">
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h2 className="text-2xl font-bold tracking-tight">Beiträge verwalten</h2>
          <div className="flex gap-2">
            <Button variant="outline" onClick={() => setBulkOpen(true)}>
              <Upload className="mr-2 h-4 w-4" />
              JSON Import
            </Button>
            <Button onClick={handleCreatePost} className="bg-primary/10 text-primary hover:bg-primary/20">
              <PlusIcon className="mr-2 h-4 w-4" />
              Neuer Beitrag
            </Button>
          </div>
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
                          {post.content_id ? (
                            <div className="flex items-center gap-3">
                              <Switch
                                checked={post.content?.status === 'published'}
                                onCheckedChange={() => handleStatusChange(post.id, post.content_id, post.content?.status)}
                              />
                              <Badge variant={post.content?.status === 'published' ? 'success' : 'secondary'}>
                                {post.content?.status === 'published' ? 'Veröffentlicht' : 'Entwurf'}
                              </Badge>
                            </div>
                          ) : (
                            <Badge variant="warning">Kein Content</Badge>
                          )}
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center">
                            <Button 
                              variant="outline" 
                              size="icon" 
                              onClick={() => handleEditPost(post.id)}
                            >
                              <PencilIcon className="h-4 w-4" />
                            </Button>
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
                          </div>
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
      </div>
      <BulkPostDialog
        open={bulkOpen}
        onOpenChange={setBulkOpen}
        onSubmit={async (entries) => {
          await bulkCreate.mutateAsync({ entries, userId: user?.id });
        }}
      />
    </DashboardLayout>
  );
};

export default PostsPage;
