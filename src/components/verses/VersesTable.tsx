
import { DailyVerse } from '@/lib/supabase';
import { format } from 'date-fns';
import { de } from 'date-fns/locale';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from '@/components/ui/button';
import { Edit2Icon } from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';
import { useTranslationsForContents, summarizeLang, SUPPORTED_LANGS } from '@/hooks/use-translations';
import { TranslationStatusList } from '@/components/translations/TranslationStatusBadge';

interface VersesTableProps {
  verses: DailyVerse[];
  onEdit: (verse: DailyVerse) => void;
}

export const VersesTable = ({ verses, onEdit }: VersesTableProps) => {
  const { isAdmin } = useAuth();
  const { data: translationsMap } = useTranslationsForContents(verses.map((v: any) => v.content_id));

  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Datum</TableHead>
            <TableHead>Bibelvers</TableHead>
            <TableHead>Referenz</TableHead>
            <TableHead>Übersetzungen</TableHead>
            <TableHead className="text-right">Teilen/Downloads</TableHead>
            {isAdmin && <TableHead className="w-[100px]">Aktionen</TableHead>}
          </TableRow>
        </TableHeader>
        <TableBody>
          {verses.map((verse) => (
            <TableRow key={verse.id}>
              <TableCell>{format(new Date(verse.date), "dd. MMMM yyyy", { locale: de })}</TableCell>
              <TableCell>{verse.verse}</TableCell>
              <TableCell>{verse.reference}</TableCell>
              <TableCell>
                <TranslationStatusList
                  statuses={Object.fromEntries(
                    SUPPORTED_LANGS.map((l) => [
                      l,
                      summarizeLang(translationsMap?.[verse.content_id], l, ['verse', 'reference']),
                    ])
                  )}
                />
              </TableCell>
              {isAdmin && (
                <TableCell>
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => onEdit(verse)}
                  >
                    <Edit2Icon className="h-4 w-4" />
                    <span className="sr-only">Bearbeiten</span>
                  </Button>
                </TableCell>
              )}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
};
