
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { Post } from '../use-posts';

export function useFetchPosts() {
  return useQuery({
    queryKey: ['posts'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('posts')
        .select('*, content(status)')
        .order('id');

      if (error) throw error;
      return data as (Post & { content: { status: 'draft' | 'published' } })[];
    }
  });
}
