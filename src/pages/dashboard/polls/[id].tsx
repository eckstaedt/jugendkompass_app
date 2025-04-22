
import { useParams } from 'react-router-dom';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useToast } from '@/hooks/use-toast';
import { usePoll, useVote } from '@/hooks/use-polls';
import { format } from 'date-fns';
import { de } from 'date-fns/locale';

const PollDetailPage = () => {
  const { id = '' } = useParams();
  const { data, isLoading } = usePoll(id);
  const vote = useVote();
  const { toast } = useToast();

  const handleVote = async (optionId: string) => {
    try {
      await vote.mutateAsync({ pollId: id, optionId });
      toast({
        title: "Stimme abgegeben",
        description: "Deine Stimme wurde erfolgreich gezählt.",
      });
    } catch (error) {
      toast({
        title: "Fehler",
        description: "Du hast bereits an dieser Umfrage teilgenommen.",
        variant: "destructive"
      });
    }
  };

  if (isLoading) {
    return (
      <DashboardLayout title="Umfrage">
        <Card className="animate-pulse">
          <CardHeader className="h-24 bg-muted" />
          <CardContent className="h-32 bg-muted mt-4" />
        </Card>
      </DashboardLayout>
    );
  }

  if (!data?.poll) {
    return (
      <DashboardLayout title="Umfrage">
        <div>Umfrage nicht gefunden</div>
      </DashboardLayout>
    );
  }

  const { poll, options } = data;
  const totalVotes = options.reduce((sum, option) => sum + option.votes, 0);

  return (
    <DashboardLayout title="Umfrage">
      <div className="mb-6">
        <h2 className="text-2xl font-bold tracking-tight">{poll.question}</h2>
        <p className="text-muted-foreground">
          Erstellt am {format(new Date(poll.created_at), "dd. MMMM yyyy", { locale: de })}
        </p>
        {poll.expires_at && (
          <p className="text-muted-foreground">
            Läuft bis {format(new Date(poll.expires_at), "dd. MMMM yyyy", { locale: de })}
          </p>
        )}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Ergebnisse</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {options.map((option) => {
            const percentage = totalVotes > 0 ? (option.votes / totalVotes) * 100 : 0;
            
            return (
              <div key={option.id} className="space-y-2">
                <div className="flex items-center justify-between">
                  <span>{option.option_text}</span>
                  <span className="text-sm text-muted-foreground">
                    {option.votes} Stimmen ({percentage.toFixed(1)}%)
                  </span>
                </div>
                <div className="relative h-2 w-full overflow-hidden rounded-full bg-secondary">
                  <div
                    className="h-full bg-primary transition-all"
                    style={{ width: `${percentage}%` }}
                  />
                </div>
                <Button
                  className="w-full"
                  variant="outline"
                  onClick={() => handleVote(option.id)}
                  disabled={!poll.is_active}
                >
                  Abstimmen
                </Button>
              </div>
            );
          })}
        </CardContent>
      </Card>
    </DashboardLayout>
  );
};

export default PollDetailPage;
