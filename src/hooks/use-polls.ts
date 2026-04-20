
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { logActivity } from '@/lib/activity-logger';
import { usePreviewLocale } from '@/contexts/PreviewLocaleContext';

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
  const { previewLang } = usePreviewLocale();
  return useQuery({
    queryKey: ['polls', { showAll }, previewLang],
    queryFn: async () => {
      if (previewLang !== 'de') {
        const { data: localizedPolls, error: pollsError } = await supabase
          .rpc('get_polls_localized', { lang: previewLang });
        if (pollsError) throw pollsError;

        const { data: localizedOptions, error: optsError } = await supabase
          .rpc('get_poll_options_localized', { lang: previewLang });
        if (optsError) throw optsError;

        const contentIds = (localizedPolls ?? []).map((p: any) => p.content_id).filter(Boolean);
        let contentMap: Record<string, any> = {};
        if (contentIds.length) {
          const { data: contents } = await supabase
            .from('content')
            .select('id, content_type, status, created_at')
            .in('id', contentIds);
          contentMap = Object.fromEntries((contents ?? []).map((c: any) => [c.id, c]));
        }

        let polls = (localizedPolls ?? []).map((p: any) => ({
          ...p,
          content: contentMap[p.content_id],
          options: (localizedOptions ?? []).filter((o: any) => o.poll_id === p.id),
        }));
        if (!showAll) polls = polls.filter((p: any) => p.is_active);
        polls.sort((a: any, b: any) => (b.created_at ?? '').localeCompare(a.created_at ?? ''));
        return polls as Poll[];
      }

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
  const { previewLang } = usePreviewLocale();
  return useQuery({
    queryKey: ['poll', id, previewLang],
    queryFn: async () => {
      if (previewLang !== 'de') {
        const { data: pollsLocalized, error: pollsError } = await supabase
          .rpc('get_polls_localized', { lang: previewLang });
        if (pollsError) throw pollsError;
        const poll = (pollsLocalized ?? []).find((p: any) => p.id === id);
        if (!poll) throw new Error('Poll not found');

        const { data: optionsLocalized, error: optsError } = await supabase
          .rpc('get_poll_options_localized', { lang: previewLang });
        if (optsError) throw optsError;
        const options = (optionsLocalized ?? []).filter((o: any) => o.poll_id === id);

        return { poll, options };
      }

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

// Add the missing useVote hook
export const useVote = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ pollId, optionId }: { pollId: string; optionId: string }) => {
      const userId = (await supabase.auth.getUser()).data.user?.id;
      
      // Check if user has already voted
      const { data: existingVote, error: checkError } = await supabase
        .from('poll_votes')
        .select()
        .eq('poll_id', pollId)
        .eq('user_id', userId);
      
      if (checkError) throw checkError;
      
      if (existingVote && existingVote.length > 0) {
        throw new Error('User has already voted on this poll');
      }
      
      // Record the vote
      const { error: voteError } = await supabase
        .from('poll_votes')
        .insert([{ poll_id: pollId, option_id: optionId, user_id: userId }]);
      
      if (voteError) throw voteError;
      
      // Increment vote count
      const { error: incrementError } = await supabase.rpc(
        'increment_poll_votes', 
        { option_id: optionId }
      );
      
      if (incrementError) throw incrementError;
      
      return true;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['poll', variables.pollId] });
    },
  });
};
