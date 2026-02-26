import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

type BulkPostEntry = {
  title: string;
  body: string;
  image_url?: string | null;
  category_id: string;
  edition_id: string;
};

export const useBulkCreatePosts = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (entries: BulkPostEntry[]) => {
      // Create content entries for all posts
      const contentInserts = entries.map(() => ({
        content_type: 'post',
        status: 'published',
      }));

      const { data: contentData, error: contentError } = await supabase
        .from('content')
        .insert(contentInserts)
        .select('id');

      if (contentError) throw contentError;
      if (!contentData || contentData.length !== entries.length) {
        throw new Error('Anzahl der erstellten Content-Einträge stimmt nicht überein.');
      }

      // Create posts with content_id references
      const postInserts = entries.map((entry, i) => ({
        title: entry.title,
        body: entry.body,
        image_url: entry.image_url || null,
        category_id: entry.category_id,
        edition_id: entry.edition_id,
        content_id: contentData[i].id,
      }));

      const { data: postData, error: postError } = await supabase
        .from('posts')
        .insert(postInserts)
        .select();

      if (postError) throw postError;
      return postData;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
  });
};
