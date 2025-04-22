
import { FeedItem } from '@/hooks/use-content-feed';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { formatDistanceToNow } from 'date-fns';
import { de } from 'date-fns/locale';
import { FileTextIcon, PieChartIcon, FileVideoIcon, CalendarIcon, BookIcon } from 'lucide-react';

const getIconForContentType = (type: string) => {
  switch (type) {
    case 'post':
      return <FileTextIcon className="h-5 w-5 text-primary" />;
    case 'poll':
      return <PieChartIcon className="h-5 w-5 text-primary" />;
    case 'video':
      return <FileVideoIcon className="h-5 w-5 text-primary" />;
    case 'verse':
      return <CalendarIcon className="h-5 w-5 text-primary" />;
    case 'impulse':
      return <BookIcon className="h-5 w-5 text-primary" />;
    default:
      return null;
  }
};

export const ContentFeedItem = ({ item }: { item: FeedItem }) => {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center gap-4">
        {getIconForContentType(item.content_type)}
        <div className="flex-1">
          <CardTitle className="text-lg">{item.title}</CardTitle>
          <p className="text-sm text-muted-foreground">
            {item.specific_date 
              ? formatDistanceToNow(new Date(item.specific_date), { addSuffix: true, locale: de })
              : item.created_at 
                ? formatDistanceToNow(new Date(item.created_at), { addSuffix: true, locale: de })
                : null
            }
          </p>
        </div>
      </CardHeader>
      <CardContent>
        {item.description && (
          <div 
            className="prose prose-sm max-w-none text-muted-foreground mb-4"
            dangerouslySetInnerHTML={{ __html: item.description }}
          />
        )}
        {item.image_url && item.content_type !== 'video' && (
          <img 
            src={item.image_url} 
            alt={item.title || 'Content image'} 
            className="w-full h-48 object-cover rounded-md"
          />
        )}
        {item.image_url && item.content_type === 'video' && (
          <video 
            src={item.image_url} 
            controls
            className="w-full h-auto rounded-md"
            poster={item.image_url}
          >
            Your browser does not support the video tag.
          </video>
        )}
      </CardContent>
    </Card>
  );
};
