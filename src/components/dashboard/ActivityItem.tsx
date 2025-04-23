
import { Activity } from "@/hooks/use-activities";
import { formatDistanceToNow } from "date-fns";
import { de } from "date-fns/locale";
import { FileTextIcon, PieChartIcon, FileVideoIcon, BellIcon, UserIcon, SparklesIcon } from "lucide-react";

const getIconForEntityType = (type: string) => {
  switch (type) {
    case 'post':
      return <FileTextIcon className="h-5 w-5 text-primary" />;
    case 'poll':
      return <PieChartIcon className="h-5 w-5 text-primary" />;
    case 'video':
      return <FileVideoIcon className="h-5 w-5 text-primary" />;
    case 'impulse':
      return <SparklesIcon className="h-5 w-5 text-primary" />;
    default:
      return <BellIcon className="h-5 w-5 text-primary" />;
  }
};

const getGermanActivityDescription = (activity: Activity): string => {
  const actionMap = {
    create: 'erstellt',
    update: 'aktualisiert',
    delete: 'gelöscht',
  };

  const entityMap = {
    post: 'Beitrag',
    poll: 'Umfrage',
    video: 'Video',
    daily_verse: 'Tagesvers',
    impulse: 'Impuls',
    notification: 'Benachrichtigung',
    user: 'Benutzer',
  };

  const action = actionMap[activity.action_type as keyof typeof actionMap] || activity.action_type;
  const entity = entityMap[activity.entity_type as keyof typeof entityMap] || activity.entity_type;

  return `${entity} wurde ${action}`;
};

export const ActivityItem = ({ activity }: { activity: Activity }) => {
  // Format user name - show both first and last name if available
  const userName = activity.user_first_name || activity.user_last_name 
    ? `${activity.user_first_name || ''} ${activity.user_last_name || ''}`.trim()
    : 'Unbekannter Benutzer';

  return (
    <div className="flex items-center gap-4 rounded-md border p-4">
      {getIconForEntityType(activity.entity_type)}
      <div className="flex-1 space-y-1">
        <p className="text-sm font-semibold leading-none">
          {getGermanActivityDescription(activity)}
        </p>
        <p className="text-xs text-muted-foreground">{activity.description}</p>
        <div className="flex items-center gap-1 mt-1">
          <UserIcon className="h-3 w-3 text-muted-foreground" />
          <p className="text-xs text-muted-foreground">{userName}</p>
        </div>
      </div>
      <div className="text-sm text-muted-foreground">
        {formatDistanceToNow(new Date(activity.created_at), { 
          addSuffix: true,
          locale: de 
        })}
      </div>
    </div>
  );
};
