
import React, { useRef } from 'react';
import { Button } from '@/components/ui/button';
import { AudioRecord } from '@/types/audio';
import { Speaker, Upload } from 'lucide-react';

interface AudioUploaderProps {
  currentAudio: AudioRecord | null;
  onFileSelected: (file: File | null) => void;
}

export function AudioUploader({ currentAudio, onFileSelected }: AudioUploaderProps) {
  const inputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file && file.type === 'audio/mpeg') {
      onFileSelected(file);
    } else {
      onFileSelected(null);
    }
  };

  return (
    <div className="space-y-4">
      {currentAudio && (
        <div className="flex items-center gap-2 text-sm">
          <Speaker className="h-4 w-4" />
          <a 
            href={currentAudio.url} 
            target="_blank" 
            rel="noopener noreferrer"
            className="text-primary hover:underline"
          >
            Aktuelle Audio-Datei anhören
          </a>
        </div>
      )}
      
      <div className="flex items-center gap-4">
        <Button
          type="button"
          variant="outline"
          onClick={() => inputRef.current?.click()}
        >
          <Upload className="mr-2 h-4 w-4" />
          {currentAudio ? 'Audio ersetzen' : 'Audio hochladen'}
        </Button>
        <input
          ref={inputRef}
          type="file"
          accept="audio/mpeg"
          className="hidden"
          onChange={handleFileChange}
        />
      </div>
    </div>
  );
}
