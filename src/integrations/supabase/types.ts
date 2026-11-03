export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.5"
  }
  public: {
    Tables: {
      activities: {
        Row: {
          action_type: string
          created_at: string
          description: string
          entity_id: string | null
          entity_type: string
          id: string
          user_id: string
        }
        Insert: {
          action_type: string
          created_at?: string
          description: string
          entity_id?: string | null
          entity_type: string
          id?: string
          user_id: string
        }
        Update: {
          action_type?: string
          created_at?: string
          description?: string
          entity_id?: string | null
          entity_type?: string
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "activities_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "activities_user_id_fkey1"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      app_analytics: {
        Row: {
          app_version: string | null
          created_at: string
          device_id: string
          event_type: string
          id: string
          platform: string
        }
        Insert: {
          app_version?: string | null
          created_at?: string
          device_id: string
          event_type: string
          id?: string
          platform?: string
        }
        Update: {
          app_version?: string | null
          created_at?: string
          device_id?: string
          event_type?: string
          id?: string
          platform?: string
        }
        Relationships: []
      }
      audios: {
        Row: {
          created_at: string
          id: string
          url: string
        }
        Insert: {
          created_at?: string
          id?: string
          url: string
        }
        Update: {
          created_at?: string
          id?: string
          url?: string
        }
        Relationships: []
      }
      categories: {
        Row: {
          created_at: string
          id: string
          name: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
        }
        Relationships: []
      }
      content: {
        Row: {
          content_type: string
          created_at: string | null
          id: string
          status: string
        }
        Insert: {
          content_type: string
          created_at?: string | null
          id?: string
          status?: string
        }
        Update: {
          content_type?: string
          created_at?: string | null
          id?: string
          status?: string
        }
        Relationships: []
      }
      content_interactions: {
        Row: {
          app_version: string | null
          content_id: string
          content_title: string | null
          content_type: string
          created_at: string
          device_id: string
          id: string
          language: string | null
          platform: string
        }
        Insert: {
          app_version?: string | null
          content_id: string
          content_title?: string | null
          content_type: string
          created_at?: string
          device_id: string
          id?: string
          language?: string | null
          platform: string
        }
        Update: {
          app_version?: string | null
          content_id?: string
          content_title?: string | null
          content_type?: string
          created_at?: string
          device_id?: string
          id?: string
          language?: string | null
          platform?: string
        }
        Relationships: []
      }
      content_translations: {
        Row: {
          content_id: string
          created_at: string
          field_name: string
          id: string
          language: string
          source_hash: string | null
          status: string
          updated_at: string
          value: string
        }
        Insert: {
          content_id: string
          created_at?: string
          field_name: string
          id?: string
          language: string
          source_hash?: string | null
          status?: string
          updated_at?: string
          value: string
        }
        Update: {
          content_id?: string
          created_at?: string
          field_name?: string
          id?: string
          language?: string
          source_hash?: string | null
          status?: string
          updated_at?: string
          value?: string
        }
        Relationships: [
          {
            foreignKeyName: "content_translations_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "content"
            referencedColumns: ["id"]
          },
        ]
      }
      device_tokens: {
        Row: {
          bible_plan_notification_hour: number
          bible_plan_notifications_enabled: boolean
          bible_plan_started: boolean
          content_notifications: boolean
          created_at: string
          device_id: string
          fcm_token: string | null
          id: string
          language: string
          notification_hour: number
          notification_minute: number
          platform: string
          timezone: string
          user_name: string | null
          verse_notifications: boolean
        }
        Insert: {
          bible_plan_notification_hour?: number
          bible_plan_notifications_enabled?: boolean
          bible_plan_started?: boolean
          content_notifications?: boolean
          created_at?: string
          device_id: string
          fcm_token?: string | null
          id?: string
          language?: string
          notification_hour?: number
          notification_minute?: number
          platform?: string
          timezone?: string
          user_name?: string | null
          verse_notifications?: boolean
        }
        Update: {
          bible_plan_notification_hour?: number
          bible_plan_notifications_enabled?: boolean
          bible_plan_started?: boolean
          content_notifications?: boolean
          created_at?: string
          device_id?: string
          fcm_token?: string | null
          id?: string
          language?: string
          notification_hour?: number
          notification_minute?: number
          platform?: string
          timezone?: string
          user_name?: string | null
          verse_notifications?: boolean
        }
        Relationships: []
      }
      editions: {
        Row: {
          body: string | null
          content_id: string | null
          id: string
          image_url: string | null
          name: string
          notification_body: string | null
          notification_sent_at: string | null
          notification_title: string | null
          pdf_url: string | null
          published_at: string | null
          title: string | null
        }
        Insert: {
          body?: string | null
          content_id?: string | null
          id?: string
          image_url?: string | null
          name: string
          notification_body?: string | null
          notification_sent_at?: string | null
          notification_title?: string | null
          pdf_url?: string | null
          published_at?: string | null
          title?: string | null
        }
        Update: {
          body?: string | null
          content_id?: string | null
          id?: string
          image_url?: string | null
          name?: string
          notification_body?: string | null
          notification_sent_at?: string | null
          notification_title?: string | null
          pdf_url?: string | null
          published_at?: string | null
          title?: string | null
        }
        Relationships: []
      }
      impulses: {
        Row: {
          content_id: string
          created_at: string
          date: string
          id: string
          image_url: string | null
          impulse_text: string
          notification_body: string | null
          notification_sent_at: string | null
          notification_title: string | null
          title: string
        }
        Insert: {
          content_id: string
          created_at?: string
          date: string
          id?: string
          image_url?: string | null
          impulse_text: string
          notification_body?: string | null
          notification_sent_at?: string | null
          notification_title?: string | null
          title: string
        }
        Update: {
          content_id?: string
          created_at?: string
          date?: string
          id?: string
          image_url?: string | null
          impulse_text?: string
          notification_body?: string | null
          notification_sent_at?: string | null
          notification_title?: string | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "impulses_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "content"
            referencedColumns: ["id"]
          },
        ]
      }
      likes: {
        Row: {
          content_id: string
          content_type: string
          created_at: string
          device_id: string
          id: string
        }
        Insert: {
          content_id: string
          content_type: string
          created_at?: string
          device_id: string
          id?: string
        }
        Update: {
          content_id?: string
          content_type?: string
          created_at?: string
          device_id?: string
          id?: string
        }
        Relationships: []
      }
      messages: {
        Row: {
          content_id: string | null
          created_at: string | null
          created_by: string | null
          id: number
          image_url: string | null
          message: string
          notification_sent_at: string | null
          title: string
        }
        Insert: {
          content_id?: string | null
          created_at?: string | null
          created_by?: string | null
          id?: number
          image_url?: string | null
          message: string
          notification_sent_at?: string | null
          title: string
        }
        Update: {
          content_id?: string | null
          created_at?: string | null
          created_by?: string | null
          id?: number
          image_url?: string | null
          message?: string
          notification_sent_at?: string | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "content"
            referencedColumns: ["id"]
          },
        ]
      }
      poll_options: {
        Row: {
          created_at: string
          id: string
          option_text: string
          poll_id: string | null
          sort_order: number
          votes: number | null
        }
        Insert: {
          created_at?: string
          id?: string
          option_text: string
          poll_id?: string | null
          sort_order?: number
          votes?: number | null
        }
        Update: {
          created_at?: string
          id?: string
          option_text?: string
          poll_id?: string | null
          sort_order?: number
          votes?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "poll_options_poll_id_fkey"
            columns: ["poll_id"]
            isOneToOne: false
            referencedRelation: "polls"
            referencedColumns: ["id"]
          },
        ]
      }
      poll_votes: {
        Row: {
          created_at: string | null
          id: string
          option_id: string
          poll_id: string
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          option_id: string
          poll_id: string
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          option_id?: string
          poll_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "poll_votes_option_id_fkey"
            columns: ["option_id"]
            isOneToOne: false
            referencedRelation: "poll_options"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "poll_votes_poll_id_fkey"
            columns: ["poll_id"]
            isOneToOne: false
            referencedRelation: "polls"
            referencedColumns: ["id"]
          },
        ]
      }
      polls: {
        Row: {
          content_id: string
          created_at: string | null
          created_by: string | null
          expires_at: string | null
          id: string
          is_active: boolean | null
          question: string
        }
        Insert: {
          content_id: string
          created_at?: string | null
          created_by?: string | null
          expires_at?: string | null
          id?: string
          is_active?: boolean | null
          question: string
        }
        Update: {
          content_id?: string
          created_at?: string | null
          created_by?: string | null
          expires_at?: string | null
          id?: string
          is_active?: boolean | null
          question?: string
        }
        Relationships: [
          {
            foreignKeyName: "polls_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "content"
            referencedColumns: ["id"]
          },
        ]
      }
      post_view_counts: {
        Row: {
          content_id: string
          last_updated_at: string
          view_count: number
        }
        Insert: {
          content_id: string
          last_updated_at?: string
          view_count?: number
        }
        Update: {
          content_id?: string
          last_updated_at?: string
          view_count?: number
        }
        Relationships: []
      }
      posts: {
        Row: {
          audio_id: string | null
          body: string
          category_id: string | null
          content_id: string | null
          created_at: string
          edition_id: string | null
          id: string
          image_url: string | null
          title: string
        }
        Insert: {
          audio_id?: string | null
          body: string
          category_id?: string | null
          content_id?: string | null
          created_at?: string
          edition_id?: string | null
          id?: string
          image_url?: string | null
          title: string
        }
        Update: {
          audio_id?: string | null
          body?: string
          category_id?: string | null
          content_id?: string | null
          created_at?: string
          edition_id?: string | null
          id?: string
          image_url?: string | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "posts_audio_id_fkey"
            columns: ["audio_id"]
            isOneToOne: false
            referencedRelation: "audios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "content"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "posts_edition_id_fkey"
            columns: ["edition_id"]
            isOneToOne: false
            referencedRelation: "editions"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          id: string
          name: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          user_id?: string
        }
        Relationships: []
      }
      subscriptions: {
        Row: {
          address_extra: string | null
          city: string
          country: string
          created_at: string
          email: string
          first_name: string
          id: string
          last_name: string
          paid: boolean
          paid_at: string | null
          paid_by: string | null
          phone: string | null
          postal_code: string
          shipping_method: Database["public"]["Enums"]["shipping_method"]
          street: string
          updated_at: string
        }
        Insert: {
          address_extra?: string | null
          city: string
          country: string
          created_at?: string
          email: string
          first_name: string
          id?: string
          last_name: string
          paid?: boolean
          paid_at?: string | null
          paid_by?: string | null
          phone?: string | null
          postal_code: string
          shipping_method?: Database["public"]["Enums"]["shipping_method"]
          street: string
          updated_at?: string
        }
        Update: {
          address_extra?: string | null
          city?: string
          country?: string
          created_at?: string
          email?: string
          first_name?: string
          id?: string
          last_name?: string
          paid?: boolean
          paid_at?: string | null
          paid_by?: string | null
          phone?: string | null
          postal_code?: string
          shipping_method?: Database["public"]["Enums"]["shipping_method"]
          street?: string
          updated_at?: string
        }
        Relationships: []
      }
      test_push_devices: {
        Row: {
          created_at: string
          created_by: string | null
          fcm_token: string
          id: string
          label: string
          language: string
          platform: string | null
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          fcm_token: string
          id?: string
          label: string
          language?: string
          platform?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string | null
          fcm_token?: string
          id?: string
          label?: string
          language?: string
          platform?: string | null
        }
        Relationships: []
      }
      translation_jobs: {
        Row: {
          attempts: number
          content_id: string
          content_type: string
          created_at: string
          id: number
          last_error: string | null
          locked_at: string | null
          locked_by: string | null
          next_retry_at: string
          record_id: string
          status: string
          updated_at: string
        }
        Insert: {
          attempts?: number
          content_id: string
          content_type: string
          created_at?: string
          id?: number
          last_error?: string | null
          locked_at?: string | null
          locked_by?: string | null
          next_retry_at?: string
          record_id: string
          status?: string
          updated_at?: string
        }
        Update: {
          attempts?: number
          content_id?: string
          content_type?: string
          created_at?: string
          id?: number
          last_error?: string | null
          locked_at?: string | null
          locked_by?: string | null
          next_retry_at?: string
          record_id?: string
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      translation_targets: {
        Row: {
          created_at: string
          is_active: boolean
          language_code: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          is_active?: boolean
          language_code: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          is_active?: boolean
          language_code?: string
          updated_at?: string
        }
        Relationships: []
      }
      users: {
        Row: {
          created_at: string
          email: string
          firstName: string
          id: string
          lastName: string
          role: string
        }
        Insert: {
          created_at?: string
          email: string
          firstName?: string
          id: string
          lastName?: string
          role?: string
        }
        Update: {
          created_at?: string
          email?: string
          firstName?: string
          id?: string
          lastName?: string
          role?: string
        }
        Relationships: []
      }
      verse_of_the_day: {
        Row: {
          content_id: string
          created_at: string
          date: string
          id: string
          image_url: string | null
          image_source_hash: string | null
          auto_scheduled: boolean
          pool_id: number | null
          ref_key: string | null
          text_key: string | null
          reference: string
          usage_count: number
          verse: string
        }
        Insert: {
          content_id: string
          created_at?: string
          date?: string
          id?: string
          image_url?: string | null
          image_source_hash?: string | null
          auto_scheduled?: boolean
          pool_id?: number | null
          reference: string
          usage_count?: number
          verse: string
        }
        Update: {
          content_id?: string
          created_at?: string
          date?: string
          id?: string
          image_url?: string | null
          image_source_hash?: string | null
          auto_scheduled?: boolean
          pool_id?: number | null
          reference?: string
          usage_count?: number
          verse?: string
        }
        Relationships: [
          {
            foreignKeyName: "verse_of_the_day_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "content"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "verse_of_the_day_new_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "content"
            referencedColumns: ["id"]
          },
        ]
      }
      videos: {
        Row: {
          content_id: string
          created_at: string | null
          description: string | null
          id: number
          image_url: string | null
          notification_sent_at: string | null
          title: string
          url: string
          user_id: string | null
        }
        Insert: {
          content_id: string
          created_at?: string | null
          description?: string | null
          id?: number
          image_url?: string | null
          notification_sent_at?: string | null
          title: string
          url: string
          user_id?: string | null
        }
        Update: {
          content_id?: string
          created_at?: string | null
          description?: string | null
          id?: number
          image_url?: string | null
          notification_sent_at?: string | null
          title?: string
          url?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "videos_content_id_fkey"
            columns: ["content_id"]
            isOneToOne: false
            referencedRelation: "content"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      verse_schedule_conflicts: {
        Row: {
          first_id: string | null
          first_date: string | null
          second_id: string | null
          second_date: string | null
          reference: string | null
          days_between: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      check_verse_conflicts: {
        Args: { p_verse: string; p_reference: string; p_date: string; p_exclude_id?: string | null }
        Returns: {
          id: string
          date: string
          reference: string
          verse: string
        }[]
      }
      get_verse_schedule_overview: {
        Args: never
        Returns: {
          year: number
          days_in_year: number
          days_planned: number
          auto_planned: number
          with_image: number
          conflicts: number
          first_free_day: string | null
        }[]
      }
      enqueue_translation_backfill_for_posts: {
        Args: { max_rows?: number }
        Returns: number
      }
      get_analytics_summary: { Args: never; Returns: Json }
      get_categories_localized: {
        Args: { lang: string }
        Returns: {
          created_at: string
          id: string
          name: string
        }[]
      }
      get_current_user_role: { Args: never; Returns: string }
      get_editions_localized: {
        Args: { lang: string }
        Returns: {
          body: string
          content_id: string
          id: string
          image_url: string
          name: string
          pdf_url: string
          published_at: string
          title: string
        }[]
      }
      get_impulses_localized: {
        Args: { lang: string }
        Returns: {
          content_id: string
          created_at: string
          date: string
          id: string
          image_url: string
          impulse_text: string
          title: string
        }[]
      }
      get_like_counts: {
        Args: { p_content_ids: string[]; p_content_type: string }
        Returns: {
          content_id: string
          like_count: number
        }[]
      }
      get_messages_localized: {
        Args: { lang: string }
        Returns: {
          content_id: string
          created_at: string
          created_by: string
          id: number
          image_url: string
          message: string
          title: string
        }[]
      }
      get_poll_options_localized: {
        Args: { lang: string }
        Returns: {
          created_at: string
          id: string
          option_text: string
          poll_id: string
          votes: number
        }[]
      }
      get_polls_localized: {
        Args: { lang: string }
        Returns: {
          content_id: string
          created_at: string
          created_by: string
          expires_at: string
          id: string
          is_active: boolean
          question: string
        }[]
      }
      get_posts_localized: {
        Args: { lang: string }
        Returns: {
          audio_id: string
          body: string
          category_id: string
          content_id: string
          created_at: string
          edition_id: string
          id: string
          image_url: string
          title: string
        }[]
      }
      get_recent_verses_localized: {
        Args: { lang: string; verse_limit?: number }
        Returns: {
          content_id: string
          date: string
          id: string
          reference: string
          verse: string
        }[]
      }
      get_vers_des_tages_today_json: { Args: never; Returns: Json }
      get_verse_archive_localized: {
        Args: { lang: string; page_limit?: number; page_offset?: number }
        Returns: {
          content_id: string
          date: string
          id: string
          image_url: string
          reference: string
          verse: string
        }[]
      }
      get_verse_by_id_localized: {
        Args: { lang: string; verse_id: string }
        Returns: {
          content_id: string
          date: string
          id: string
          reference: string
          verse: string
        }[]
      }
      get_verse_of_day_localized: {
        Args: { lang: string }
        Returns: {
          content_id: string
          date: string
          id: string
          reference: string
          verse: string
        }[]
      }
      get_videos_localized: {
        Args: { lang: string }
        Returns: {
          content_id: string
          created_at: string
          description: string
          id: number
          image_url: string
          title: string
          url: string
          user_id: string
        }[]
      }
      increment_poll_votes: { Args: { option_id: string }; Returns: undefined }
      increment_verse_usage: { Args: { verse_id: string }; Returns: undefined }
      is_admin:
        | { Args: never; Returns: boolean }
        | { Args: { user_id: string }; Returns: boolean }
      toggle_like: {
        Args: {
          p_content_id: string
          p_content_type: string
          p_device_id: string
        }
        Returns: {
          like_count: number
          liked: boolean
        }[]
      }
      tr: {
        Args: {
          p_content_id: string
          p_fallback: string
          p_field: string
          p_lang: string
        }
        Returns: string
      }
    }
    Enums: {
      app_role: "admin" | "user"
      shipping_method: "standard" | "pickup"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["admin", "user"],
      shipping_method: ["standard", "pickup"],
    },
  },
} as const
