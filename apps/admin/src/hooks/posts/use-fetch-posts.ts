
import { useInfiniteQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { Post } from '../use-posts';
import { usePreviewLocale } from '@/contexts/PreviewLocaleContext';

const PAGE_SIZE = 20;

export function useFetchPosts() {
  const { previewLang } = usePreviewLocale();

  return useInfiniteQuery({
    queryKey: ['posts', previewLang],
    queryFn: async ({ pageParam = 0 }) => {
      const from = pageParam * PAGE_SIZE;
      const to = from + PAGE_SIZE - 1;

      if (previewLang !== 'de') {
        const { data: localized, error: rpcError } = await supabase
          .rpc('get_posts_localized', { lang: previewLang });
        if (rpcError) throw rpcError;

        const sorted = [...(localized ?? [])].sort((a: any, b: any) =>
          (a.id ?? '').localeCompare(b.id ?? '')
        );
        const slice = sorted.slice(from, to + 1);
        const contentIds = slice.map((p: any) => p.content_id).filter(Boolean);
        let statusMap: Record<string, string> = {};
        if (contentIds.length) {
          const { data: contents } = await supabase
            .from('content')
            .select('id, status')
            .in('id', contentIds);
          statusMap = Object.fromEntries((contents ?? []).map((c: any) => [c.id, c.status]));
        }
        return slice.map((p: any) => ({
          ...p,
          content: { status: statusMap[p.content_id] ?? 'published' },
        })) as (Post & { content: { status: 'draft' | 'published' } })[];
      }

      const { data, error } = await supabase
        .from('posts')
        .select('*, content(status)')
        .order('id')
        .range(from, to);

      if (error) throw error;
      return data as (Post & { content: { status: 'draft' | 'published' } })[];
    },
    initialPageParam: 0,
    getNextPageParam: (lastPage, allPages) => {
      return lastPage.length === PAGE_SIZE ? allPages.length : undefined;
    },
  });
}
