import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { useQueryClient } from '@tanstack/react-query';

export type PreviewLang = 'de' | 'en' | 'es' | 'ru' | 'pl';

export const PREVIEW_LANGS: { code: PreviewLang; label: string; name: string }[] = [
  { code: 'de', label: 'DE', name: 'Deutsch' },
  { code: 'en', label: 'EN', name: 'Englisch' },
  { code: 'es', label: 'ES', name: 'Spanisch' },
  { code: 'ru', label: 'RU', name: 'Russisch' },
  { code: 'pl', label: 'PL', name: 'Polnisch' },
];

const STORAGE_KEY = 'preview-lang';
const VALID: PreviewLang[] = ['de', 'en', 'es', 'ru', 'pl'];

type PreviewLocaleContextValue = {
  previewLang: PreviewLang;
  setPreviewLang: (lang: PreviewLang) => void;
};

const PreviewLocaleContext = createContext<PreviewLocaleContextValue | undefined>(undefined);

export const PreviewLocaleProvider = ({ children }: { children: ReactNode }) => {
  const [previewLang, setPreviewLangState] = useState<PreviewLang>(() => {
    if (typeof window === 'undefined') return 'de';
    const stored = localStorage.getItem(STORAGE_KEY) as PreviewLang | null;
    return stored && VALID.includes(stored) ? stored : 'de';
  });

  const queryClient = useQueryClient();

  const setPreviewLang = (lang: PreviewLang) => {
    setPreviewLangState(lang);
    try {
      localStorage.setItem(STORAGE_KEY, lang);
    } catch {
      /* ignore */
    }
  };

  useEffect(() => {
    queryClient.invalidateQueries();
  }, [previewLang, queryClient]);

  return (
    <PreviewLocaleContext.Provider value={{ previewLang, setPreviewLang }}>
      {children}
    </PreviewLocaleContext.Provider>
  );
};

export const usePreviewLocale = () => {
  const ctx = useContext(PreviewLocaleContext);
  if (!ctx) throw new Error('usePreviewLocale must be used within PreviewLocaleProvider');
  return ctx;
};
