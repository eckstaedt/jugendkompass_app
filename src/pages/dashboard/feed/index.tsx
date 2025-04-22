
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { useContentFeed } from '@/hooks/use-content-feed';
import { ContentFeedItem } from '@/components/dashboard/ContentFeedItem';

const FeedPage = () => {
  const { data: feedItems, isLoading: isLoadingFeed } = useContentFeed();
  
  return (
    <DashboardLayout title="Aktueller Feed">
      <Card>
        <CardHeader>
          <CardTitle>Content Feed</CardTitle>
          <CardDescription>
            Alle veröffentlichten Inhalte in chronologischer Reihenfolge
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoadingFeed ? (
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="h-[100px] animate-pulse rounded-md bg-muted" />
              ))}
            </div>
          ) : feedItems && feedItems.length > 0 ? (
            <div className="space-y-4">
              {feedItems.map((item) => (
                <ContentFeedItem key={item.content_id} item={item} />
              ))}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">Keine Inhalte gefunden.</p>
          )}
        </CardContent>
      </Card>
    </DashboardLayout>
  );
};

export default FeedPage;
