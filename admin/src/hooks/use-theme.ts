
import { useEffect, useState } from "react";

export interface Theme {
  theme: "light" | "dark";
  setTheme: (theme: "light" | "dark") => void;
  toggleTheme: () => void;
}

const THEME_KEY = "theme";
const getSystemTheme = (): "light" | "dark" =>
  window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";

export const useTheme = (): Theme => {
  const [theme, setThemeState] = useState<"light" | "dark">(
    () => (localStorage.getItem(THEME_KEY) as "light" | "dark") || getSystemTheme()
  );

  useEffect(() => {
    document.documentElement.classList.toggle("dark", theme === "dark");
    localStorage.setItem(THEME_KEY, theme);
  }, [theme]);

  // Listen for system preference changes
  useEffect(() => {
    const listener = (e: MediaQueryListEvent) => {
      if (!localStorage.getItem(THEME_KEY)) {
        setThemeState(e.matches ? "dark" : "light");
      }
    };
    window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", listener);
    return () =>
      window.matchMedia("(prefers-color-scheme: dark)").removeEventListener("change", listener);
  }, []);

  const setTheme = (newTheme: "light" | "dark") => setThemeState(newTheme);
  const toggleTheme = () => setThemeState((prev) => (prev === "light" ? "dark" : "light"));

  return { theme, setTheme, toggleTheme };
};
