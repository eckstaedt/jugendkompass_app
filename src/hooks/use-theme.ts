
export interface Theme {
  theme: string | undefined;
  setTheme: (theme: string) => void;
}

export const useTheme = (): Theme => {
  // Einfache Implementierung ohne die next-themes Abhängigkeit
  return {
    theme: "light",
    setTheme: () => {
      // In dieser Version verwenden wir nur das Light-Theme
      console.log("Theme wird aktualisiert");
    },
  };
};
