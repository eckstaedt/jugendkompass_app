import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

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
    mutationFn: async ({ question, expires_at, options }: CreatePollInput) => {
      const { data: content, error: contentError } = await supabase
        .from('content')
        .insert([{ content_type: 'poll', status: 'published' }])
        .select()
        .single();

      if (contentError) throw contentError;

      const { data: poll, error: pollError } = await supabase
        .from('polls')
        .insert([{ 
          question, 
          expires_at,
          content_id: content.id,
          created_by: (await supabase.auth.getUser()).data.user?.id
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

      return poll;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['polls'] });
    },
  });
};

export const useVote = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ pollId, optionId }: { pollId: string; optionId: string }) => {
      const { error: voteError } = await supabase
        .from('poll_votes')
        .insert([{ poll_id: pollId, option_id: optionId, user_id: (await supabase.auth.getUser()).data.user?.id }]);

      if (voteError) throw voteError;

      const { error: incrementError } = await supabase.rpc('increment_poll_votes', { option_id: optionId });
      
      if (incrementError) throw incrementError;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['poll', variables.pollId] });
    },
  });
};
