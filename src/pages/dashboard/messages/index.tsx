
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { useMessages, useCreateMessage, useUpdateMessage, useDeleteMessage } from '@/hooks/use-messages';
import { useToast } from '@/hooks/use-toast';
import MessageForm from '@/components/messages/MessageForm';
import MessageItem from '@/components/messages/MessageItem';

const MessagesPage = () => {
  const { data: messages, isLoading } = useMessages();
  const createMessage = useCreateMessage();
  const updateMessage = useUpdateMessage();
  const deleteMessage = useDeleteMessage();
  const { toast } = useToast();

  const handleDelete = async (id: number) => {
    try {
      await deleteMessage.mutateAsync(id);
      toast({
        title: "Erfolg",
        description: "Die Nachricht wurde gelöscht.",
      });
    } catch (error) {
      toast({
        title: "Fehler",
        description: "Beim Löschen der Nachricht ist ein Fehler aufgetreten.",
        variant: "destructive",
      });
    }
  };

  return (
    <DashboardLayout title="Kurznachrichten">
      <div className="max-w-4xl mx-auto space-y-8">
        <div className="bg-card rounded-lg border p-6">
          <h2 className="text-lg font-semibold mb-4">Neue Nachricht</h2>
          <MessageForm
            onSubmit={async (data) => {
              try {
                await createMessage.mutateAsync(data);
                toast({
                  title: "Erfolg",
                  description: "Die Nachricht wurde erstellt.",
                });
              } catch (error) {
                toast({
                  title: "Fehler",
                  description: "Beim Erstellen der Nachricht ist ein Fehler aufgetreten.",
                  variant: "destructive",
                });
              }
            }}
            isSubmitting={createMessage.isPending}
          />
        </div>

        {isLoading ? (
          <div>Lädt...</div>
        ) : (
          <div className="space-y-4">
            {messages?.map((message) => (
              <MessageItem
                key={message.id}
                message={message}
                onUpdate={updateMessage.mutateAsync}
                onDelete={handleDelete}
              />
            ))}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
};

export default MessagesPage;
