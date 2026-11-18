
import { useMemo } from 'react';
import { useFetchPosts } from './posts/use-fetch-posts';
import { useDeletePost } from './posts/use-delete-post';
import { useCreatePost } from './posts/use-create-post';
import { useUpdatePost } from './posts/use-update-post';
import { useUpdatePostStatus } from './posts/use-update-post-status';
export * from './posts/types';

export function usePosts() {
  const {
    data,
    isLoading,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useFetchPosts();
  const { mutate: deletePost } = useDeletePost();
  const { mutate: createPost } = useCreatePost();
  const { mutate: updatePost } = useUpdatePost();
  const { mutate: updatePostStatus } = useUpdatePostStatus();

  const posts = useMemo(
    () => data?.pages.flatMap((page) => page) ?? [],
    [data]
  );

  return {
    posts,
    isLoading,
    deletePost,
    createPost,
    updatePost,
    updatePostStatus,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  };
}
