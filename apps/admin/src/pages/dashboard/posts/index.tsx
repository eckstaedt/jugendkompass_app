
import React, { useState, useRef, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { usePosts } from '@/hooks/use-posts';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from '@/components/ui/table';
import { Switch } from '@/components/ui/switch';
import { PlusIcon, TrashIcon, PencilIcon, Upload, SearchIcon } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { AlertDialog, AlertDialogTrigger, AlertDialogContent, AlertDialogHeader, AlertDialogTitle, AlertDialogDescription, AlertDialogFooter, AlertDialogCancel, AlertDialogAction } from '@/components/ui/alert-dialog';
import { Badge } from '@/components/ui/badge';
import { useAuth } from '@/contexts/AuthContext';
import { BulkPostDialog } from '@/components/posts/BulkPostDialog';
import { useBulkCreatePosts } from '@/hooks/posts/use-bulk-create-posts';
import { useTranslationsForContents, summarizeLang, SUPPORTED_LANGS } from '@/hooks/use-translations';
import { TranslationStatusList } from '@/components/translations/TranslationStatusBadge';
import { BackfillButton } from '@/components/translations/BackfillButton';

const PostsPage = () => {
  const { posts, isLoading, deletePost, updatePostStatus, fetchNextPage, hasNextPage, isFetchingNextPage } = usePosts();
  const { data: translationsMap } = useTranslationsForContents(posts.map((p: any) => p.content_id));
  const [bulkOpen, setBulkOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const bulkCreate = useBulkCreatePosts();
  const navigate = useNavigate();
  const { user } = useAuth();
  const loadMoreRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = loadMoreRef.current;
    if (!el) return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && hasNextPage && !isFetchingNextPage) {
          fetchNextPage();
        }
      },
      { threshold: 0.1 }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [hasNextPage, isFetchingNextPage, fetchNextPage]);

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
            <BackfillButton contentType="post" invalidateKeys={['posts']} />
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

        <div className="relative">
          <SearchIcon className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Beitrag suchen..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-9"
          />
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
                    <TableHead>Übersetzungen</TableHead>
                    <TableHead>Aktionen</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {(() => {
                    const filtered = posts.filter(p => 
                      p.title.toLowerCase().includes(searchQuery.toLowerCase())
                    );
                    return filtered.length > 0 ? (
                    filtered.map((post) => (
                      <TableRow key={post.id}>
                        <TableCell className="font-medium">{post.title}</TableCell>
                        <TableCell>
                          {post.content_id ? (
                            <Switch
                              checked={post.content?.status === 'published'}
                              onCheckedChange={() => handleStatusChange(post.id, post.content_id, post.content?.status)}
                            />
                          ) : (
                            <Badge variant="warning">Kein Content</Badge>
                          )}
                        </TableCell>
                        <TableCell>
                          <TranslationStatusList
                            statuses={Object.fromEntries(
                              SUPPORTED_LANGS.map((l) => [
                                l,
                                summarizeLang(translationsMap?.[post.content_id], l, ['title', 'body']),
                              ])
                            )}
                          />
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
                      <TableCell colSpan={4} className="text-center py-6 text-muted-foreground">
                        {searchQuery ? 'Keine Beiträge gefunden' : 'Keine Beiträge vorhanden'}
                      </TableCell>
                    </TableRow>
                  );
                  })()}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        <div ref={loadMoreRef} className="flex justify-center py-4">
          {isFetchingNextPage && (
            <div className="h-6 w-6 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
          )}
        </div>
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
