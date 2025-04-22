
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/hooks/use-toast';
import { logActivity } from '@/lib/activity-logger';

export function useUpdatePostStatus() {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ contentId, status }: { contentId: string, status: 'draft' | 'published' }) => {
      console.log('Updating post status:', { contentId, status });
      
      if (!contentId) {
        throw new Error('Content ID is required to update post status');
      }
      
      const { data: existingContent, error: fetchError } = await supabase
        .from('content')
        .select('*')
        .eq('id', contentId)
        .maybeSingle();
        
      if (fetchError) {
        console.error('Error fetching content:', fetchError);
        throw fetchError;
      }
      
      if (!existingContent) {
        throw new Error(`Content with ID ${contentId} not found`);
      }
      
      const { error } = await supabase
        .from('content')
        .update({ status })
        .eq('id', contentId);

      if (error) {
        console.error('Error updating post status:', error);
        throw error;
      }

      await logActivity({
        action_type: 'update',
        entity_type: 'post',
        entity_id: contentId,
        description: `Post status updated to ${status}`
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
      toast({
        title: "Status aktualisiert",
        description: "Der Status des Beitrags wurde erfolgreich aktualisiert",
        variant: "success",
      });
    },
    onError: (error) => {
      console.error('Error in updatePostStatus mutation:', error);
      toast({
        title: "Fehler",
        description: "Der Status konnte nicht aktualisiert werden. Bitte überprüfen Sie die Konsole für Details.",
        variant: "destructive",
      });
    }
  });
}
