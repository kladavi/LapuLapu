"use client";

import { useEffect } from "react";
import { usePMData } from "../context/PMContext";

/**
 * Reads the ui.theme setting and applies `data-theme` on <html>.
 * Falls back to "light" when no data is loaded.
 */
export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const { data } = usePMData();
  const theme = data?.settings?.ui?.theme ?? "light";

  useEffect(() => {
    const html = document.documentElement;

    if (theme === "system") {
      // Detect system preference
      const mq = window.matchMedia("(prefers-color-scheme: dark)");
      const apply = () => html.setAttribute("data-theme", mq.matches ? "dark" : "light");
      apply();
      mq.addEventListener("change", apply);
      return () => mq.removeEventListener("change", apply);
    }

    html.setAttribute("data-theme", theme);
  }, [theme]);

  return <>{children}</>;
}
