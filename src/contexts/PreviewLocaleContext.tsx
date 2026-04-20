import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { useQueryClient } from '@tanstack/react-query';

export type PreviewLang = 'de' | 'en';

const STORAGE_KEY = 'preview-lang';

type PreviewLocaleContextValue = {
  previewLang: PreviewLang;
  setPreviewLang: (lang: PreviewLang) => void;
};

const PreviewLocaleContext = createContext<PreviewLocaleContextValue | undefined>(undefined);

export const PreviewLocaleProvider = ({ children }: { children: ReactNode }) => {
  const [previewLang, setPreviewLangState] = useState<PreviewLang>(() => {
    if (typeof window === 'undefined') return 'de';
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored === 'en' ? 'en' : 'de';
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
    // Invalidate all queries that depend on the preview language
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
