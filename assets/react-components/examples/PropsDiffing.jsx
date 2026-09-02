import React, { useEffect, useRef, useState } from "react";

export function PropsDiffing({ label, payload }) {
  const renders = useRef(0);
  const [bytes, setBytes] = useState(0);
  renders.current += 1;

  useEffect(() => {
    setBytes(JSON.stringify(payload).length);
  }, [payload]);

  return (
    <div className="rounded-md border p-4">
      <h3 className="font-medium">{label}</h3>
      <dl className="mt-2 grid grid-cols-2 gap-x-4 text-sm">
        <dt className="text-muted-foreground">counter</dt>
        <dd>{payload.counter}</dd>
        <dt className="text-muted-foreground">renders</dt>
        <dd>{renders.current}</dd>
        <dt className="text-muted-foreground">reconstructed payload</dt>
        <dd>{bytes} bytes</dd>
      </dl>
    </div>
  );
}
