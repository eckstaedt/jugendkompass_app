
import { EditorContent, useEditor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import TextAlign from '@tiptap/extension-text-align';
import TextStyle from '@tiptap/extension-text-style';
import Image from '@tiptap/extension-image';
import React, { useRef } from 'react';
import { Button } from '@/components/ui/button';
import {
  Bold,
  Italic,
  AlignLeft,
  AlignCenter,
  AlignRight,
  Image as ImageIcon,
} from 'lucide-react';

interface RichTextEditorProps {
  content: string;
  onChange: (content: string) => void;
}

const RichTextEditor = ({ content, onChange }: RichTextEditorProps) => {
  const fileInputRef = useRef<HTMLInputElement>(null);

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
      }),
    ],
    content,
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML());
    },
  });

  if (!editor) {
    return null;
  }

  // Fix the setColor function to use the editor's chain API correctly
  function setColor(color: string) {
    editor.chain().focus().setColor(color).run();
  }

  function handleImageUpload(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (readerEvent) => {
      const base64 = readerEvent.target?.result as string;
      if (base64) {
        editor.chain().focus().setImage({ src: base64 }).run();
      }
    };
    reader.readAsDataURL(file);
    // Reset input so you can add the same image again if needed
    event.target.value = "";
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
        {/* Color Picker */}
        <div className="flex items-center gap-1">
          <Palette className="h-4 w-4 text-primary" />
          <div className="flex gap-0.5">
            {COLORS.map((color) => (
              <button
                key={color}
                type="button"
                className="w-4 h-4 rounded-full border border-gray-200 hover:border-black"
                style={{ background: color }}
                onClick={() => setColor(color)}
                aria-label={`Farbe ${color}`}
              />
            ))}
          </div>
        </div>
        {/* Image Upload */}
        <Button
          variant="ghost"
          size="sm"
          onClick={handleImageButtonClick}
          type="button"
        >
          <ImageIcon className="h-4 w-4" />
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
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
