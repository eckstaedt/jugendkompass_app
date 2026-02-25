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
      audios: {
        Row: {
          id: string
          url: string
        }
        Insert: {
          id?: string
          url: string
        }
        Update: {
          id?: string
          url?: string
        }
        Relationships: []
      }
      categories: {
        Row: {
          id: string
          name: string
        }
        Insert: {
          id?: string
          name: string
        }
        Update: {
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
      editions: {
        Row: {
          id: string
          name: string
          published_at: string | null
        }
        Insert: {
          id?: string
          name: string
          published_at?: string | null
        }
        Update: {
          id?: string
          name?: string
          published_at?: string | null
        }
        Relationships: []
      }
      favorites: {
        Row: {
          created_at: string
          id: string
          user_id: string
          verse_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          user_id: string
          verse_id: string
        }
        Update: {
          created_at?: string
          id?: string
          user_id?: string
          verse_id?: string
        }
        Relationships: []
      }
      impulses: {
        Row: {
          content_id: string
          date: string
          id: string
          image_url: string | null
          impulse_text: string
        }
        Insert: {
          content_id: string
          date: string
          id?: string
          image_url?: string | null
          impulse_text: string
        }
        Update: {
          content_id?: string
          date?: string
          id?: string
          image_url?: string | null
          impulse_text?: string
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
      poll_options: {
        Row: {
          id: string
          option_text: string
          poll_id: string | null
          votes: number | null
        }
        Insert: {
          id?: string
          option_text: string
          poll_id?: string | null
          votes?: number | null
        }
        Update: {
          id?: string
          option_text?: string
          poll_id?: string | null
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
          option_id: string | null
          poll_id: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          option_id?: string | null
          poll_id?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          option_id?: string | null
          poll_id?: string | null
          user_id?: string | null
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
      posts: {
        Row: {
          audio_id: string | null
          body: string
          category_id: string | null
          content_id: string | null
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
          date: string
          id: string
          reference: string
          verse: string
        }
        Insert: {
          content_id: string
          date?: string
          id?: string
          reference: string
          verse: string
        }
        Update: {
          content_id?: string
          date?: string
          id?: string
          reference?: string
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
    }
    Views: {
      current_verse: {
        Row: {
          content_id: string | null
          date: string | null
          id: string | null
          reference: string | null
          verse: string | null
        }
        Relationships: []
      }
      current_verse_v: {
        Row: {
          content_id: string | null
          date: string | null
          id: string | null
          reference: string | null
          verse: string | null
        }
        Relationships: []
      }
      favorites_with_verse: {
        Row: {
          created_at: string | null
          date: string | null
          favorite_id: string | null
          reference: string | null
          user_id: string | null
          verse: string | null
          verse_id: string | null
        }
        Relationships: []
      }
      vers_archiv: {
        Row: {
          content_id: string | null
          date: string | null
          id: string | null
          reference: string | null
          verse: string | null
        }
        Insert: {
          content_id?: string | null
          date?: string | null
          id?: string | null
          reference?: string | null
          verse?: string | null
        }
        Update: {
          content_id?: string | null
          date?: string | null
          id?: string | null
          reference?: string | null
          verse?: string | null
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
      vers_archiv_v: {
        Row: {
          content_id: string | null
          date: string | null
          id: string | null
          reference: string | null
          verse: string | null
        }
        Insert: {
          content_id?: string | null
          date?: string | null
          id?: string | null
          reference?: string | null
          verse?: string | null
        }
        Update: {
          content_id?: string | null
          date?: string | null
          id?: string | null
          reference?: string | null
          verse?: string | null
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
    }
    Functions: {
      get_current_user_role: { Args: never; Returns: string }
      get_vers_des_tages_today_json: { Args: never; Returns: Json }
      increment_poll_votes: { Args: { option_id: string }; Returns: undefined }
      is_admin:
        | { Args: never; Returns: boolean }
        | { Args: { user_id: string }; Returns: boolean }
    }
    Enums: {
      app_role: "admin" | "user"
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
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
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
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
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
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
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
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
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
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
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
    },
  },
} as const
