
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

export type Poll = {
  id: string;
  question: string;
  created_at: string;
  expires_at: string | null;
  is_active: boolean;
  created_by: string;
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
        .select('*')
        .order('created_at', { ascending: false });

      if (!showAll) {
        query.eq('is_active', true);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as Poll[];
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
      // Insert the poll first
      const { data: poll, error: pollError } = await supabase
        .from('polls')
        .insert([{ question, expires_at }])
        .select()
        .single();

      if (pollError) throw pollError;

      // Then insert all options
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
      const { error } = await supabase
        .from('poll_votes')
        .insert([{ poll_id: pollId, option_id: optionId }]);

      if (error) throw error;

      // Update the votes count
      const { error: updateError } = await supabase.rpc('increment_poll_votes', { option_id: optionId });
      if (updateError) throw updateError;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['poll', variables.pollId] });
    },
  });
};
