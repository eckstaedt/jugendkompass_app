import { Button } from '@/components/ui/button';
import { Languages, Loader2 } from 'lucide-react';
import { useRetranslateContent, SUPPORTED_LANGS } from '@/hooks/use-translations';

interface Props {
  contentId: string | null | undefined;
  variant?: 'default' | 'outline' | 'ghost' | 'secondary';
  size?: 'default' | 'sm' | 'lg' | 'icon';
  label?: string;
  className?: string;
}

export function RetranslateButton({
  contentId,
  variant = 'outline',
  size = 'sm',
  label = 'Übersetzung neu erzeugen',
  className,
}: Props) {
  const retranslate = useRetranslateContent();
  const disabled = !contentId || retranslate.isPending;

  const handleClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!contentId) return;
    retranslate.mutate({
      content_id: contentId,
      target_languages: [...SUPPORTED_LANGS],
      force: true,
    });
  };

  return (
    <Button
      type="button"
      variant={variant}
      size={size}
      onClick={handleClick}
      disabled={disabled}
      className={className}
    >
      {retranslate.isPending ? (
        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
      ) : (
        <Languages className="mr-2 h-4 w-4" />
      )}
      {size === 'icon' ? null : label}
    </Button>
  );
}
