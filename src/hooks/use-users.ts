
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { fetchUsers, updateUserRole } from '@/lib/users';
import { useToast } from './use-toast';

export function useUsers() {
  const { toast } = useToast();
  const queryClient = useQueryClient();

  const { data: users = [], isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: fetchUsers
  });

  const { mutate: updateRole } = useMutation({
    mutationFn: ({ userId, role }: { userId: string, role: 'admin' | 'user' }) =>
      updateUserRole(userId, role),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      toast({
        title: "Erfolg",
        description: "Benutzerrolle wurde aktualisiert",
        variant: "success",
      });
    },
    onError: () => {
      toast({
        title: "Fehler",
        description: "Benutzerrolle konnte nicht aktualisiert werden",
        variant: "destructive",
      });
    }
  });

  return { users, isLoading, error, updateRole };
}
