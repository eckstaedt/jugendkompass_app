
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from './use-toast';

export type Edition = {
  id: string;
  name: string;
  published_at: string | null;
  release_date: string | null;
  title: string | null;
  body: string | null;
  image_url: string | null;
  pdf_url: string | null;
  content_id: string | null;
};

export type CreateEditionParams = {
  name: string;
  title?: string;
  body?: string;
  image_url?: string | null;
  pdfFile?: File | null;
  release_date?: string | null;
};

export type UpdateEditionParams = {
  id: string;
  name: string;
  title?: string;
  body?: string;
  image_url?: string | null;
  pdfFile?: File | null;
  keepExistingPdf?: boolean;
  release_date?: string | null;
};

export function useEditions() {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: editions = [], isLoading } = useQuery({
    queryKey: ['editions'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('editions')
        .select('*')
        .order('release_date', { ascending: false, nullsFirst: false });

      if (error) throw error;
      return data as Edition[];
    }
  });

  const uploadPdf = async (file: File): Promise<string> => {
    const ext = file.name.split('.').pop();
    const fileName = `${crypto.randomUUID()}.${ext}`;
    const { error } = await supabase.storage.from('pdfs').upload(fileName, file);
    if (error) throw error;
    const { data } = supabase.storage.from('pdfs').getPublicUrl(fileName);
    return data.publicUrl;
  };

  const { mutate: createEdition, isPending: isCreating } = useMutation({
    mutationFn: async (params: CreateEditionParams) => {
      let pdf_url: string | null = null;
      if (params.pdfFile) {
        pdf_url = await uploadPdf(params.pdfFile);
      }

      const { error } = await supabase
        .from('editions')
        .insert([{
          name: params.name,
          title: params.title || null,
          body: params.body || null,
          image_url: params.image_url || null,
          pdf_url,
          release_date: params.release_date || null,
        }]);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['editions'] });
      toast({ title: "Erfolg", description: "Ausgabe wurde erstellt", variant: "success" });
    },
    onError: () => {
      toast({ title: "Fehler", description: "Ausgabe konnte nicht erstellt werden", variant: "destructive" });
    }
  });

  const { mutate: updateEdition, isPending: isUpdating } = useMutation({
    mutationFn: async (params: UpdateEditionParams) => {
      let pdf_url: string | null | undefined = undefined;

      if (params.pdfFile) {
        pdf_url = await uploadPdf(params.pdfFile);
      } else if (!params.keepExistingPdf) {
        pdf_url = null;
      }

      const updateData: Record<string, unknown> = {
        name: params.name,
        title: params.title || null,
        body: params.body || null,
        image_url: params.image_url || null,
        release_date: params.release_date || null,
      };

      if (pdf_url !== undefined) {
        updateData.pdf_url = pdf_url;
      }

      const { error } = await supabase
        .from('editions')
        .update(updateData)
        .eq('id', params.id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['editions'] });
      toast({ title: "Erfolg", description: "Ausgabe wurde aktualisiert", variant: "success" });
    },
    onError: () => {
      toast({ title: "Fehler", description: "Ausgabe konnte nicht aktualisiert werden", variant: "destructive" });
    }
  });

  const { mutate: deleteEdition, isPending: isDeleting } = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('editions')
        .delete()
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['editions'] });
      toast({ title: "Erfolg", description: "Ausgabe wurde gelöscht", variant: "success" });
    },
    onError: () => {
      toast({ title: "Fehler", description: "Ausgabe konnte nicht gelöscht werden", variant: "destructive" });
    }
  });

  return { editions, isLoading, createEdition, isCreating, updateEdition, isUpdating, deleteEdition, isDeleting };
}
