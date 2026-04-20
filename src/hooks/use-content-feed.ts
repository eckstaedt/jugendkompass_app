
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { usePreviewLocale } from '@/contexts/PreviewLocaleContext';

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
  const { previewLang } = usePreviewLocale();
  return useQuery({
    queryKey: ['content-feed', previewLang],
    queryFn: async () => {
      if (previewLang === 'en') {
        const { data, error } = await supabase
          .rpc('get_content_feed_localized', { lang: 'en' });
        if (error) {
          console.error('Error fetching localized content feed:', error);
          throw error;
        }
        const sorted = [...(data ?? [])].sort((a: any, b: any) => {
          const so = (a.sort_order ?? 0) - (b.sort_order ?? 0);
          if (so !== 0) return so;
          const sd = (a.specific_date ?? '').localeCompare(b.specific_date ?? '');
          if (sd !== 0) return sd;
          return (b.created_at ?? '').localeCompare(a.created_at ?? '');
        });
        return sorted as FeedItem[];
      }

      const { data, error } = await supabase
        .from('content_feed')
        .select('*')
        .order('sort_order', { ascending: true })
        .order('specific_date', { ascending: true })
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error fetching content feed:', error);
        throw error;
      }
      return data as FeedItem[];
    }
  });
}
