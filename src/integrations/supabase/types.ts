export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      audios: {
        Row: {
          id: number
          url: string
        }
        Insert: {
          id?: never
          url: string
        }
        Update: {
          id?: never
          url?: string
        }
        Relationships: []
      }
      categories: {
        Row: {
          id: number
          name: string
        }
        Insert: {
          id?: never
          name: string
        }
        Update: {
          id?: never
          name?: string
        }
        Relationships: []
      }
      content: {
        Row: {
          content_type: string
          created_at: string | null
          id: number
        }
        Insert: {
          content_type: string
          created_at?: string | null
          id?: never
        }
        Update: {
          content_type?: string
          created_at?: string | null
          id?: never
        }
        Relationships: []
      }
      editions: {
        Row: {
          id: number
          name: string
          published_at: string | null
        }
        Insert: {
          id?: never
          name: string
          published_at?: string | null
        }
        Update: {
          id?: never
          name?: string
          published_at?: string | null
        }
        Relationships: []
      }
      impulses: {
        Row: {
          content_id: number | null
          id: number
          impulse_text: string
        }
        Insert: {
          content_id?: number | null
          id?: never
          impulse_text: string
        }
        Update: {
          content_id?: number | null
          id?: never
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
      messages: {
        Row: {
          content_id: number | null
          id: number
          message: string
        }
        Insert: {
          content_id?: number | null
          id?: never
          message: string
        }
        Update: {
          content_id?: number | null
          id?: never
          message?: string
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
          id: number
          option_text: string
          poll_id: number | null
        }
        Insert: {
          id?: never
          option_text: string
          poll_id?: number | null
        }
        Update: {
          id?: never
          option_text?: string
          poll_id?: number | null
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
      polls: {
        Row: {
          content_id: number | null
          id: number
          question: string
        }
        Insert: {
          content_id?: number | null
          id?: never
          question: string
        }
        Update: {
          content_id?: number | null
          id?: never
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
          audio_id: number | null
          body: string
          category_id: number | null
          content_id: number | null
          edition_id: number | null
          id: number
          image_url: string | null
          title: string
        }
        Insert: {
          audio_id?: number | null
          body: string
          category_id?: number | null
          content_id?: number | null
          edition_id?: number | null
          id?: never
          image_url?: string | null
          title: string
        }
        Update: {
          audio_id?: number | null
          body?: string
          category_id?: number | null
          content_id?: number | null
          edition_id?: number | null
          id?: never
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
      users: {
        Row: {
          created_at: string
          email: string
          id: string
          role: string
        }
        Insert: {
          created_at?: string
          email: string
          id: string
          role?: string
        }
        Update: {
          created_at?: string
          email?: string
          id?: string
          role?: string
        }
        Relationships: []
      }
      verse_of_the_day: {
        Row: {
          content_id: number | null
          id: number
          reference: string
          verse: string
        }
        Insert: {
          content_id?: number | null
          id?: never
          reference: string
          verse: string
        }
        Update: {
          content_id?: number | null
          id?: never
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
        ]
      }
      videos: {
        Row: {
          content_id: number | null
          id: number
          title: string
          url: string
        }
        Insert: {
          content_id?: number | null
          id?: never
          title: string
          url: string
        }
        Update: {
          content_id?: number | null
          id?: never
          title?: string
          url?: string
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
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DefaultSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
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
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
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
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
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
    | { schema: keyof Database },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof Database },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof Database }
  ? Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
