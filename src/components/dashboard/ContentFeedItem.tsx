import { FeedItem } from '@/hooks/use-content-feed';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { formatDistanceToNow } from 'date-fns';
import { de } from 'date-fns/locale';
import { FileTextIcon, PieChartIcon, FileVideoIcon, CalendarIcon, BookIcon } from 'lucide-react';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { usePoll } from '@/hooks/use-polls';
import { Label } from '@/components/ui/label';

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

const PollResults = ({ pollId }: { pollId: string }) => {
  const { data: pollData } = usePoll(pollId);
  
  if (!pollData) return null;
  
  const { options } = pollData;
  const totalVotes = options?.reduce((sum, option) => sum + (option.votes || 0), 0) || 0;

  return (
    <div className="space-y-4">
      <RadioGroup className="gap-3">
        {options?.map((option) => {
          const percentage = totalVotes > 0 ? ((option.votes || 0) / totalVotes) * 100 : 0;
          
          return (
            <div key={option.id} className="flex items-center space-x-2">
              <RadioGroupItem value={option.id} id={option.id} disabled />
              <Label htmlFor={option.id} className="flex-1">
                <div className="flex justify-between">
                  <span>{option.option_text}</span>
                  <span className="text-muted-foreground">{percentage.toFixed(1)}%</span>
                </div>
                <div className="w-full h-2 bg-muted rounded-full mt-1">
                  <div 
                    className="h-full bg-primary rounded-full" 
                    style={{ width: `${percentage}%` }}
                  />
                </div>
              </Label>
            </div>
          );
        })}
      </RadioGroup>
      <p className="text-sm text-muted-foreground">
        {totalVotes} {totalVotes === 1 ? 'Stimme' : 'Stimmen'} insgesamt
      </p>
    </div>
  );
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
        {item.content_type === 'poll' && item.entity_id && (
          <PollResults pollId={item.entity_id} />
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
