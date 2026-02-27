
import { createClient } from '@supabase/supabase-js';
import { supabase as supabaseClient } from '@/integrations/supabase/client';

// Re-export the client from the auto-generated file
export const supabase = supabaseClient;

// Typen für Auth
export type User = {
  id: string;
  email: string;
  role: string;
  created_at: string;
};

// Typen für Beiträge
export type Post = {
  id: string;
  title: string;
  content: string;
  category: string;
  edition_id: string;
  author_id: string;
  created_at: string;
  updated_at: string;
  published: boolean;
  image_url?: string;
};

// Typen für Editionen
export type Edition = {
  id: string;
  name: string;
  year: number;
  description?: string;
  created_at: string;
};

// Typen für Umfragen
export type Poll = {
  id: string;
  question: string;
  edition_id: string;
  created_at: string;
  expires_at?: string;
  published: boolean;
};

export type PollOption = {
  id: string;
  poll_id: string;
  option_text: string;
  votes: number;
};

// Typen für Videos
export type Video = {
  id: number;
  content_id: string;
  title: string;
  description: string | null;
  url: string;
  image_url: string | null;
  user_id: string | null;
  created_at: string | null;
  content: {
    content_type: string;
    created_at: string;
    id: string;
    status: string;
  };
};

// Typen für tägliche Verse - Updated to match database schema
export type DailyVerse = {
  id: string;
  content_id: string;
  verse: string;        // Changed from verse_text to match actual DB field
  reference: string;    // Changed from verse_reference to match actual DB field
  date: string;
  created_at?: string;
  content?: {
    content_type: string;
    created_at: string;
    id: string;
    status: string;
  };
};

// Typen für Benachrichtigungen
export type Notification = {
  id: string;
  title: string;
  body: string;
  link?: string;
  audience: string;
  sent_at?: string;
  created_at: string;
};

// Typen für App-Statistiken
export type AppStat = {
  id: string;
  user_id?: string;
  event_type: string;
  event_data?: any;
  created_at: string;
};
