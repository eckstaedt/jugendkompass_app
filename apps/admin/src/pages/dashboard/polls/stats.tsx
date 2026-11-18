
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { ChartContainer, ChartTooltip } from '@/components/ui/chart';
import { usePolls, type Poll } from '@/hooks/use-polls';
import { BarChart, Bar, XAxis, YAxis, Tooltip } from 'recharts';
import { format } from 'date-fns';
import { de } from 'date-fns/locale';

const PollStatsPage = () => {
  const { data: polls, isLoading } = usePolls(true);

  if (isLoading) {
    return (
      <DashboardLayout title="Umfrage-Statistiken">
        <div className="grid gap-4 md:grid-cols-2">
          <Card className="animate-pulse">
            <CardHeader className="h-24 bg-muted" />
            <CardContent className="h-80 bg-muted mt-4" />
          </Card>
          <Card className="animate-pulse">
            <CardHeader className="h-24 bg-muted" />
            <CardContent className="h-80 bg-muted mt-4" />
          </Card>
        </div>
      </DashboardLayout>
    );
  }

  const pollsWithTotalVotes = polls?.map(poll => {
    const totalVotes = poll.options?.reduce((sum, option) => sum + (option.votes || 0), 0) || 0;
    return {
      name: poll.question,
      votes: totalVotes,
      date: format(new Date(poll.created_at), 'dd. MMMM yyyy', { locale: de }),
    };
  }) || [];

  const config = {
    votes: {
      label: 'Stimmen',
      theme: {
        light: '#8B5CF6',
        dark: '#9b87f5',
      },
    },
  };

  return (
    <DashboardLayout title="Umfrage-Statistiken">
      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Stimmen pro Umfrage</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-[400px]">
              <ChartContainer config={config}>
                <BarChart data={pollsWithTotalVotes}>
                  <XAxis 
                    dataKey="date" 
                    angle={-45}
                    textAnchor="end"
                    height={70}
                  />
                  <YAxis />
                  <Tooltip content={<ChartTooltip />} />
                  <Bar 
                    dataKey="votes"
                    name="votes"
                    fill="var(--color-votes)"
                  />
                </BarChart>
              </ChartContainer>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Aktive vs. Abgelaufene Umfragen</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="mt-4 space-y-4">
              {[
                { label: 'Aktive Umfragen', value: polls?.filter(p => p.is_active).length || 0 },
                { label: 'Abgelaufene Umfragen', value: polls?.filter(p => !p.is_active).length || 0 },
              ].map((stat) => (
                <div key={stat.label} className="flex items-center justify-between">
                  <span className="text-muted-foreground">{stat.label}</span>
                  <span className="font-medium">{stat.value}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
};

export default PollStatsPage;
