
import { EditorContent, useEditor, type Editor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import TextAlign from '@tiptap/extension-text-align';
import TextStyle from '@tiptap/extension-text-style';
import Image from '@tiptap/extension-image';
import React, { useRef, useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { Button } from '@/components/ui/button';
import {
  Bold,
  Italic,
  AlignLeft,
  AlignCenter,
  AlignRight,
  Image as ImageIcon,
  Loader2,
} from 'lucide-react';

interface RichTextEditorProps {
  content: string;
  onChange: (content: string) => void;
  /**
   * Supabase storage bucket for images inserted into the text. When set,
   * images (button, paste, drag & drop) are uploaded and inserted as a URL
   * instead of being embedded as base64.
   */
  imageUploadBucket?: string;
}

const RichTextEditor = ({ content, onChange, imageUploadBucket }: RichTextEditorProps) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(0);
  // Paste/drop handlers are created once with the editor, so they reach the
  // live editor instance through this ref.
  const editorRef = useRef<Editor | null>(null);
  const { toast } = useToast();

  // Uploads the file and returns its public URL (or a base64 data URI when
  // no bucket is configured).
  async function imageSource(file: File): Promise<string> {
    if (!imageUploadBucket) {
      return await new Promise<string>((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result as string);
        reader.onerror = () => reject(reader.error);
        reader.readAsDataURL(file);
      });
    }
    const ext = (file.name.split('.').pop() || file.type.split('/')[1] || 'jpg').toLowerCase();
    const path = `inline/${crypto.randomUUID()}.${ext}`;
    const { error } = await supabase.storage
      .from(imageUploadBucket)
      .upload(path, file, { contentType: file.type || undefined });
    if (error) throw error;
    return supabase.storage.from(imageUploadBucket).getPublicUrl(path).data.publicUrl;
  }

  async function insertImages(files: File[], position?: number) {
    const images = files.filter((f) => f.type.startsWith('image/'));
    for (const file of images) {
      setUploading((n) => n + 1);
      try {
        const src = await imageSource(file);
        const current = editorRef.current;
        if (!current) return;
        const chain = current.chain().focus();
        if (position !== undefined) {
          chain.insertContentAt(position, { type: 'image', attrs: { src } }).run();
        } else {
          chain.setImage({ src }).run();
        }
      } catch (error) {
        console.error('Image upload failed', error);
        toast({
          title: 'Bild konnte nicht hochgeladen werden',
          description: error instanceof Error ? error.message : String(error),
          variant: 'destructive',
        });
      } finally {
        setUploading((n) => n - 1);
      }
    }
  }

  const editor = useEditor({
    extensions: [
      StarterKit,
      TextStyle,
      TextAlign.configure({
        types: ['heading', 'paragraph'],
        alignments: ['left', 'center', 'right'],
        defaultAlignment: 'left',
      }),
      
      Image.configure({
        inline: false,
        allowBase64: true,
        HTMLAttributes: { class: 'rounded-md max-w-full h-auto' },
      }),
    ],
    content,
    editorProps: {
      handlePaste: (_view, event) => {
        const files = Array.from(event.clipboardData?.files ?? []);
        if (!files.some((f) => f.type.startsWith('image/'))) return false;
        event.preventDefault();
        void insertImages(files);
        return true;
      },
      handleDrop: (view, event) => {
        const files = Array.from(event.dataTransfer?.files ?? []);
        if (!files.some((f) => f.type.startsWith('image/'))) return false;
        event.preventDefault();
        const pos = view.posAtCoords({ left: event.clientX, top: event.clientY })?.pos;
        void insertImages(files, pos);
        return true;
      },
    },
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML());
    },
  });

  editorRef.current = editor;

  if (!editor) {
    return null;
  }

  function handleImageUpload(event: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(event.target.files ?? []);
    // Reset input so you can add the same image again if needed
    event.target.value = "";
    if (files.length > 0) void insertImages(files);
  }

  function handleImageButtonClick() {
    fileInputRef.current?.click();
  }

  return (
    <div className="border rounded-md">
      <div className="border-b p-2 flex gap-2 flex-wrap bg-muted/50 items-center">
        <Button
          variant="ghost"
          size="sm"
          onClick={() => editor.chain().focus().toggleBold().run()}
          data-active={editor.isActive('bold')}
          className={`${editor.isActive('bold') ? 'bg-muted' : ''}`}
          type="button"
        >
          <Bold className="h-4 w-4" />
        </Button>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => editor.chain().focus().toggleItalic().run()}
          data-active={editor.isActive('italic')}
          className={`${editor.isActive('italic') ? 'bg-muted' : ''}`}
          type="button"
        >
          <Italic className="h-4 w-4" />
        </Button>
        {/* Image Upload */}
        <Button
          variant="ghost"
          size="sm"
          onClick={handleImageButtonClick}
          type="button"
          title="Bild an der Cursor-Position einfügen"
          disabled={uploading > 0}
        >
          {uploading > 0 ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <ImageIcon className="h-4 w-4" />
          )}
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            multiple
            className="hidden"
            onChange={handleImageUpload}
            tabIndex={-1}
          />
        </Button>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => editor.chain().focus().setTextAlign('left').run()}
          data-active={editor.isActive({ textAlign: 'left' })}
          className={`${editor.isActive({ textAlign: 'left' }) ? 'bg-muted' : ''}`}
          type="button"
        >
          <AlignLeft className="h-4 w-4" />
        </Button>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => editor.chain().focus().setTextAlign('center').run()}
          data-active={editor.isActive({ textAlign: 'center' })}
          className={`${editor.isActive({ textAlign: 'center' }) ? 'bg-muted' : ''}`}
          type="button"
        >
          <AlignCenter className="h-4 w-4" />
        </Button>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => editor.chain().focus().setTextAlign('right').run()}
          data-active={editor.isActive({ textAlign: 'right' })}
          className={`${editor.isActive({ textAlign: 'right' }) ? 'bg-muted' : ''}`}
          type="button"
        >
          <AlignRight className="h-4 w-4" />
        </Button>
      </div>
      <EditorContent 
        editor={editor} 
        className="prose prose-sm max-w-none p-4 min-h-[200px] focus:outline-none"
      />
    </div>
  );
};

export default RichTextEditor;
