import React from 'react';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { BarChart2Icon, BookIcon, FileTextIcon, PieChartIcon, UsersIcon, FileVideoIcon, CalendarIcon } from 'lucide-react';
import { useActivities } from '@/hooks/use-activities';
import { ActivityItem } from '@/components/dashboard/ActivityItem';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

type DashboardCardProps = {
  title: string;
  value: string | number;
  description: string;
  icon: React.ReactNode;
  className?: string;
};

const DashboardCard = ({ title, value, description, icon, className }: DashboardCardProps) => (
  <Card className={className}>
    <CardHeader className="flex flex-row items-center justify-between pb-2">
      <CardTitle className="text-sm font-medium">{title}</CardTitle>
      {icon}
    </CardHeader>
    <CardContent>
      <div className="text-2xl font-bold">{value}</div>
      <p className="text-xs text-muted-foreground">{description}</p>
    </CardContent>
  </Card>
);

const DashboardPage = () => {
  const { data: activities, isLoading: isLoadingActivities } = useActivities();
  
  const { data: postStats } = useQuery({
    queryKey: ['dashboard-stats-posts'],
    queryFn: async () => {
      const { count: totalPosts } = await supabase
        .from('posts')
        .select('*', { count: 'exact' });
        
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const { count: newPosts } = await supabase
        .from('posts')
        .select('*', { count: 'exact' })
        .gte('created_at', thirtyDaysAgo.toISOString());
        
      return { total: totalPosts || 0, new: newPosts || 0 };
    }
  });

  const { data: pollStats } = useQuery({
    queryKey: ['dashboard-stats-polls'],
    queryFn: async () => {
      const { count: totalPolls } = await supabase
        .from('polls')
        .select('*', { count: 'exact' });
        
      const { count: activePolls } = await supabase
        .from('polls')
        .select('*', { count: 'exact' })
        .eq('is_active', true);
        
      return { total: totalPolls || 0, active: activePolls || 0 };
    }
  });

  const { data: videoStats } = useQuery({
    queryKey: ['dashboard-stats-videos'],
    queryFn: async () => {
      const { count: totalVideos } = await supabase
        .from('videos')
        .select('*', { count: 'exact' });
        
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const { count: newVideos } = await supabase
        .from('videos')
        .select('*', { count: 'exact' })
        .gte('created_at', thirtyDaysAgo.toISOString());
        
      return { total: totalVideos || 0, new: newVideos || 0 };
    }
  });

  const { data: verseStats } = useQuery({
    queryKey: ['dashboard-stats-verses'],
    queryFn: async () => {
      const { count: totalVerses } = await supabase
        .from('verse_of_the_day')
        .select('*', { count: 'exact' });
        
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const { count: newVerses } = await supabase
        .from('verse_of_the_day')
        .select('*', { count: 'exact' })
        .gte('created_at', thirtyDaysAgo.toISOString());
        
      return { total: totalVerses || 0, new: newVerses || 0 };
    }
  });

  const { data: userStats } = useQuery({
    queryKey: ['dashboard-stats-users'],
    queryFn: async () => {
      const { count: totalUsers } = await supabase
        .from('users')
        .select('*', { count: 'exact' });
        
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const { count: newUsers } = await supabase
        .from('users')
        .select('*', { count: 'exact' })
        .gte('created_at', thirtyDaysAgo.toISOString());
        
      return { total: totalUsers || 0, new: newUsers || 0 };
    }
  });

  const { data: editionStats } = useQuery({
    queryKey: ['dashboard-stats-editions'],
    queryFn: async () => {
      const { count: totalEditions } = await supabase
        .from('editions')
        .select('*', { count: 'exact' });
        
      return { total: totalEditions || 0 };
    }
  });

  const { data: impulseStats } = useQuery({
    queryKey: ['dashboard-stats-impulses'],
    queryFn: async () => {
      const { count: totalImpulses } = await supabase
        .from('impulses')
        .select('*', { count: 'exact' });
        
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const { count: newImpulses } = await supabase
        .from('impulses')
        .select('*', { count: 'exact' })
        .gte('created_at', thirtyDaysAgo.toISOString());
        
      return { total: totalImpulses || 0, new: newImpulses || 0 };
    }
  });

  return (
    <DashboardLayout title="Dashboard">
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <DashboardCard 
          title="Beiträge" 
          value={postStats?.total || '...'} 
          description={`${postStats?.new || 0} neue Beiträge im letzten Monat`} 
          icon={<FileTextIcon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Umfragen" 
          value={pollStats?.total || '...'} 
          description={`${pollStats?.active || 0} aktive Umfragen`} 
          icon={<PieChartIcon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Videos" 
          value={videoStats?.total || '...'} 
          description={`${videoStats?.new || 0} neue Videos im letzten Monat`} 
          icon={<FileVideoIcon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Tagesverse" 
          value={verseStats?.total || '...'} 
          description={`${verseStats?.new || 0} neue Verse im letzten Monat`} 
          icon={<CalendarIcon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Benutzer" 
          value={userStats?.total || '...'} 
          description={`${userStats?.new || 0} neue Benutzer im letzten Monat`} 
          icon={<UsersIcon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Impulse" 
          value={impulseStats?.total || '...'} 
          description={`${impulseStats?.new || 0} neue Impulse im letzten Monat`} 
          icon={<BookIcon className="h-5 w-5 text-primary" />} 
        />
        <DashboardCard 
          title="Editionen" 
          value={editionStats?.total || '...'} 
          description="Ausgaben des Jugendkompass" 
          icon={<BookIcon className="h-5 w-5 text-primary" />} 
        />
      </div>
      
      <div className="mt-8">
        <Card>
          <CardHeader>
            <CardTitle>Neueste Aktivitäten</CardTitle>
            <CardDescription>
              Die letzten Inhaltsänderungen im Admin-Dashboard
            </CardDescription>
          </CardHeader>
          <CardContent>
            {isLoadingActivities ? (
              <div className="space-y-4">
                {[1, 2, 3].map((i) => (
                  <div key={i} className="h-[76px] animate-pulse rounded-md bg-muted" />
                ))}
              </div>
            ) : activities && activities.length > 0 ? (
              <div className="space-y-4">
                {activities.map((activity) => (
                  <ActivityItem key={activity.id} activity={activity} />
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">Keine Aktivitäten gefunden.</p>
            )}
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
};

export default DashboardPage;
