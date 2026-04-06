"use client";

import { PMProvider } from "../context/PMContext";
import { ThemeProvider } from "./ThemeProvider";

export function ClientProviders({ children }: { children: React.ReactNode }) {
  return (
    <PMProvider>
      <ThemeProvider>{children}</ThemeProvider>
    </PMProvider>
  );
}
