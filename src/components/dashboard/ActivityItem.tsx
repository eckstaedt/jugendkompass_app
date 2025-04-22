
import { Activity } from "@/hooks/use-activities";
import { formatDistanceToNow } from "date-fns";
import { de } from "date-fns/locale";
import { FileTextIcon, PieChartIcon, FileVideoIcon, BellIcon } from "lucide-react";

const getIconForEntityType = (type: string) => {
  switch (type) {
    case 'post':
      return <FileTextIcon className="h-5 w-5 text-primary" />;
    case 'poll':
      return <PieChartIcon className="h-5 w-5 text-primary" />;
    case 'video':
      return <FileVideoIcon className="h-5 w-5 text-primary" />;
    default:
      return <BellIcon className="h-5 w-5 text-primary" />;
  }
};

export const ActivityItem = ({ activity }: { activity: Activity }) => {
  return (
    <div className="flex items-center gap-4 rounded-md border p-4">
      {getIconForEntityType(activity.entity_type)}
      <div className="flex-1 space-y-1">
        <p className="text-sm font-medium leading-none">
          {activity.action_type}
        </p>
        <p className="text-sm text-muted-foreground">
          {activity.description}
        </p>
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
