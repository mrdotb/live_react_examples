import React, { useEffect } from "react";
import { useLiveReact } from "live_react";
import { Toaster, toast } from "sonner";

export function ServerEvents() {
  const { handleEvent } = useLiveReact();

  useEffect(() => {
    handleEvent("info", ({ message }) => toast.info(message));
    handleEvent("error", ({ message }) => toast.error(message));
  }, []);

  return <Toaster />;
}
