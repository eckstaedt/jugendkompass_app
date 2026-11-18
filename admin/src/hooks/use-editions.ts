
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from './use-toast';

export type Edition = {
  id: string;
  name: string;
  published_at: string | null;
  title: string | null;
  body: string | null;
  image_url: string | null;
  pdf_url: string | null;
  content_id: string | null;
  notification_title: string | null;
  notification_body: string | null;
  notification_sent_at: string | null;
};

export type CreateEditionParams = {
  name: string;
  title?: string;
  body?: string;
  image_url?: string | null;
  pdfFile?: File | null;
  published_at?: string | null;
  notification_title?: string | null;
  notification_body?: string | null;
};

export type UpdateEditionParams = {
  id: string;
  name: string;
  title?: string;
  body?: string;
  image_url?: string | null;
  pdfFile?: File | null;
  keepExistingPdf?: boolean;
  published_at?: string | null;
  notification_title?: string | null;
  notification_body?: string | null;
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
        .order('published_at', { ascending: false, nullsFirst: false });

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
          published_at: params.published_at || null,
          notification_title: params.notification_title || null,
          notification_body: params.notification_body || null,
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

      const updateData: {
        name: string;
        title: string | null;
        body: string | null;
        image_url: string | null;
        published_at: string | null;
        notification_title: string | null;
        notification_body: string | null;
        pdf_url?: string | null;
      } = {
        name: params.name,
        title: params.title || null,
        body: params.body || null,
        image_url: params.image_url || null,
        published_at: params.published_at || null,
        notification_title: params.notification_title || null,
        notification_body: params.notification_body || null,
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
