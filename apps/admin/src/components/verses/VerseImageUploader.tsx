import React, { useRef, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Upload as UploadIcon } from "lucide-react";

type Props = {
  value: string | null;
  onChange: (url: string) => void;
  required?: boolean;
};

export const VerseImageUploader: React.FC<Props> = ({ value, onChange, required }) => {
  const [uploading, setUploading] = useState(false);
  const [preview, setPreview] = useState(value || "");
  const fileInput = useRef<HTMLInputElement>(null);

  React.useEffect(() => {
    setPreview(value || "");
  }, [value]);

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith("image/")) {
      alert("Bitte nur Bilder (JPEG, PNG) hochladen.");
      return;
    }
    if (file.size > 3 * 1024 * 1024) {
      alert("Das Bild darf maximal 3MB groß sein.");
      return;
    }

    setUploading(true);
    const ext = file.name.split(".").pop();
    const fileName = `${Math.random().toString(36).slice(2, 11)}.${ext}`;

    const { error } = await supabase.storage
      .from("verse-images")
      .upload(fileName, file, { upsert: true });
    if (error) {
      alert("Fehler beim Hochladen des Bildes.");
      setUploading(false);
      return;
    }
    const { data } = supabase.storage.from("verse-images").getPublicUrl(fileName);
    setPreview(data.publicUrl);
    onChange(data.publicUrl);
    setUploading(false);
  };

  return (
    <div>
      <label className="block font-medium mb-1 text-sm">
        Bild (JPEG, PNG, max. 3MB){required ? "*" : ""}
      </label>
      <div className="flex gap-4 items-center">
        <Button
          type="button"
          variant="outline"
          onClick={() => fileInput.current?.click()}
          disabled={uploading}
        >
          <UploadIcon className="mr-2 h-4 w-4" />
          Bild auswählen
        </Button>
        <input
          type="file"
          accept="image/png, image/jpeg"
          style={{ display: "none" }}
          ref={fileInput}
          onChange={handleFileChange}
        />
        {uploading && <span className="text-sm text-muted-foreground">Hochladen...</span>}
        {preview && (
          <img src={preview} alt="Vorschau" className="w-20 h-14 object-cover rounded border" />
        )}
      </div>
      {required && !preview && (
        <div className="text-sm text-destructive mt-2">Bild erforderlich</div>
      )}
    </div>
  );
};
