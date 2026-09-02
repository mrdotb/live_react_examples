import React from "react";

// `children` here is not React markup — it's HEEx, rendered by the
// LiveView and handed over as a slot. React treats it like any other
// child: it doesn't know or care where it came from.
export function Slots({
  count,
  children,
}: {
  count: number;
  children: React.ReactNode;
}) {
  return (
    <div className="flex items-center gap-4">
      <span className="text-xl">{count}</span>
      {children}
    </div>
  );
}
