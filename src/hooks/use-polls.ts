
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { logActivity } from '@/lib/activity-logger';

export type Poll = {
  id: string;
  question: string;
  created_at: string;
  expires_at: string | null;
  is_active: boolean | null;
  created_by: string;
  options?: PollOption[];
};

export type PollOption = {
  id: string;
  poll_id: string;
  option_text: string;
  votes: number;
};

export type CreatePollInput = {
  question: string;
  expires_at?: string;
  options: string[];
  userId?: string;
};

export const usePolls = (showAll = false) => {
  return useQuery({
    queryKey: ['polls', { showAll }],
    queryFn: async () => {
      const query = supabase
        .from('polls')
        .select(`
          *,
          content!polls_content_id_fkey (
            id,
            content_type,
            status,
            created_at
          ),
          options:poll_options(*)
        `)
        .order('created_at', { ascending: false });

      if (!showAll) {
        query.eq('is_active', true);
      }

      const { data: polls, error } = await query;
      if (error) throw error;
      
      return polls as Poll[];
    },
  });
};

export const usePoll = (id: string) => {
  return useQuery({
    queryKey: ['poll', id],
    queryFn: async () => {
      const { data: poll, error: pollError } = await supabase
        .from('polls')
        .select('*')
        .eq('id', id)
        .single();

      if (pollError) throw pollError;

      const { data: options, error: optionsError } = await supabase
        .from('poll_options')
        .select('*')
        .eq('poll_id', id);

      if (optionsError) throw optionsError;

      return {
        poll,
        options,
      };
    },
    enabled: !!id,
  });
};

export const useCreatePoll = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ question, expires_at, options, userId }: CreatePollInput) => {
      const { data: content, error: contentError } = await supabase
        .from('content')
        .insert([{ content_type: 'poll', status: 'published' }])
        .select()
        .single();

      if (contentError) throw contentError;

      const currentUserId = userId || (await supabase.auth.getUser()).data.user?.id;

      const { data: poll, error: pollError } = await supabase
        .from('polls')
        .insert([{ 
          question, 
          expires_at,
          content_id: content.id,
          created_by: currentUserId
        }])
        .select()
        .single();

      if (pollError) throw pollError;

      const optionsToInsert = options.map(option_text => ({
        poll_id: poll.id,
        option_text,
      }));

      const { error: optionsError } = await supabase
        .from('poll_options')
        .insert(optionsToInsert);

      if (optionsError) throw optionsError;

      if (currentUserId && poll?.id) {
        await logActivity(
          currentUserId,
          'poll',
          'create',
          String(poll.id),
          'Umfrage erstellt'
        );
      }

      return poll;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['polls'] });
    },
  });
};

export const useUpdatePoll = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, question, expires_at, is_active, userId }: { id: string, question: string, expires_at?: string, is_active?: boolean, userId?: string }) => {
      const { data, error } = await supabase
        .from('polls')
        .update({ question, expires_at, is_active })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;

      const currentUserId = userId || (await supabase.auth.getUser()).data.user?.id;
      if (currentUserId) {
        await logActivity(
          currentUserId,
          'poll',
          'update',
          String(id),
          'Umfrage bearbeitet'
        );
      }

      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['polls'] });
    },
  });
};

export const useDeletePoll = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, userId }: { id: string, userId?: string }) => {
      const { error } = await supabase
        .from('polls')
        .delete()
        .eq('id', id);

      if (error) throw error;

      const currentUserId = userId || (await supabase.auth.getUser()).data.user?.id;
      if (currentUserId) {
        await logActivity(
          currentUserId,
          'poll',
          'delete',
          String(id),
          'Umfrage gelöscht'
        );
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['polls'] });
    },
  });
};
