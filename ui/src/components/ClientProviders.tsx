"use client";

import { PMProvider } from "../context/PMContext";

export function ClientProviders({ children }: { children: React.ReactNode }) {
  return <PMProvider>{children}</PMProvider>;
}
