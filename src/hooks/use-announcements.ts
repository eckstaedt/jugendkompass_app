import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import type { SupabaseClient } from '@supabase/supabase-js';
import { supabase } from '@/integrations/supabase/client';

// The table is newer than the generated types, so it is used untyped here.
const db = supabase as unknown as SupabaseClient;

export const ANNOUNCEMENT_BUCKET = 'announcements';

export interface Announcement {
  id: string;
  title: string;
  message: string;
  image_url: string | null;
  starts_at: string;
  ends_at: string;
  is_active: boolean;
  dismissible: boolean;
  show_once: boolean;
  created_at: string;
}

export interface AnnouncementInput {
  title: string;
  message: string;
  starts_at: string;
  ends_at: string;
  is_active: boolean;
  dismissible: boolean;
  show_once: boolean;
  /** New image to upload. */
  imageFile?: File;
  /** true = remove the current image. */
  removeImage?: boolean;
}

export type AnnouncementStatus = 'live' | 'scheduled' | 'expired' | 'inactive';

export function announcementStatus(a: Announcement, now = new Date()): AnnouncementStatus {
  if (!a.is_active) return 'inactive';
  if (new Date(a.ends_at) <= now) return 'expired';
  if (new Date(a.starts_at) > now) return 'scheduled';
  return 'live';
}

const QUERY_KEY = ['announcements'];

async function uploadImage(file: File): Promise<string> {
  const ext = (file.name.split('.').pop() || file.type.split('/')[1] || 'jpg').toLowerCase();
  const path = `${crypto.randomUUID()}.${ext}`;
  const { error } = await db.storage
    .from(ANNOUNCEMENT_BUCKET)
    .upload(path, file, { contentType: file.type || undefined });
  if (error) throw error;
  return db.storage.from(ANNOUNCEMENT_BUCKET).getPublicUrl(path).data.publicUrl;
}

function rowFromInput(input: AnnouncementInput) {
  return {
    title: input.title.trim(),
    message: input.message.trim(),
    starts_at: input.starts_at,
    ends_at: input.ends_at,
    is_active: input.is_active,
    dismissible: input.dismissible,
    show_once: input.show_once,
  };
}

export function useAnnouncements() {
  return useQuery({
    queryKey: QUERY_KEY,
    queryFn: async () => {
      const { data, error } = await db
        .from('app_announcements')
        .select('id, title, message, image_url, starts_at, ends_at, is_active, dismissible, show_once, created_at')
        .order('starts_at', { ascending: false });
      if (error) throw error;
      return (data ?? []) as Announcement[];
    },
  });
}

export function useSaveAnnouncement() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, input }: { id?: string; input: AnnouncementInput }) => {
      const row: Record<string, unknown> = rowFromInput(input);
      if (input.imageFile) row.image_url = await uploadImage(input.imageFile);
      else if (input.removeImage) row.image_url = null;

      if (id) {
        const { error } = await db.from('app_announcements').update(row).eq('id', id);
        if (error) throw error;
      } else {
        const { error } = await db.from('app_announcements').insert(row);
        if (error) throw error;
      }
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: QUERY_KEY }),
  });
}

export function useSetAnnouncementActive() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      const { error } = await db.from('app_announcements').update({ is_active }).eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: QUERY_KEY }),
  });
}

export function useDeleteAnnouncement() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await db.from('app_announcements').delete().eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: QUERY_KEY }),
  });
}
