
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
};

export type CreateEditionParams = {
  name: string;
  title?: string;
  body?: string;
  image_url?: string | null;
  pdfFile?: File | null;
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
        .order('name');

      if (error) throw error;
      return data as Edition[];
    }
  });

  const { mutate: createEdition, isPending: isCreating } = useMutation({
    mutationFn: async (params: CreateEditionParams) => {
      let pdf_url: string | null = null;

      if (params.pdfFile) {
        const ext = params.pdfFile.name.split('.').pop();
        const fileName = `${crypto.randomUUID()}.${ext}`;
        const { error } = await supabase.storage.from('pdfs').upload(fileName, params.pdfFile);
        if (error) throw error;
        const { data } = supabase.storage.from('pdfs').getPublicUrl(fileName);
        pdf_url = data.publicUrl;
      }

      const { error } = await supabase
        .from('editions')
        .insert([{
          name: params.name,
          title: params.title || null,
          body: params.body || null,
          image_url: params.image_url || null,
          pdf_url,
        }]);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['editions'] });
      toast({
        title: "Erfolg",
        description: "Ausgabe wurde erstellt",
        variant: "success",
      });
    },
    onError: () => {
      toast({
        title: "Fehler",
        description: "Ausgabe konnte nicht erstellt werden",
        variant: "destructive",
      });
    }
  });

  return { editions, isLoading, createEdition, isCreating };
}
