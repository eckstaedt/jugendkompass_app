
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

export type FeedItem = {
  content_id: string;
  content_type: string;
  created_at: string | null;
  title: string | null;
  description: string | null;
  image_url: string | null;
  entity_id: string;
  sort_order: number | null;
  specific_date: string | null;
};

export function useContentFeed() {
  return useQuery({
    queryKey: ['content-feed'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('content_feed')
        .select('*');

      if (error) throw error;
      return data as FeedItem[];
    }
  });
}
