
export type Post = {
  id: string;
  title: string;
  body: string;
  category_id: string;
  edition_id: string;
  content_id: string | null;
  audio_id: string | null;
  image_url: string | null;
};

export type CreatePostParams = {
  title: string;
  body: string;
  category_id: string;
  edition_id: string;
  status: 'draft' | 'published';
  author_id?: string;
  image_url?: string | null;
};

export type UpdatePostParams = {
  id: string;
  data: {
    title: string;
    body: string;
    audio_id?: string | null;
  };
};

export type UpdatePostStatusParams = {
  id: string; 
  status: string;
  userId: string;
};
