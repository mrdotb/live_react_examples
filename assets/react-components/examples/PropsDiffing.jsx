import React, { useEffect, useRef, useState } from "react";

// Measures what actually arrived, instead of recomputing it. LiveReact
// writes the real wire payload onto this component's wrapper element as
// `data-props` (the full or partial snapshot) and `data-props-diff` (the
// JSON Patch, when diffing is on) - so reading those attributes directly is
// the only honest way to report their size.
function describeAttr(value) {
  if (value === null) return "not present";
  if (value === "") return "empty (0 bytes)";
  return `${new TextEncoder().encode(value).length} bytes`;
}

export function PropsDiffing({ label, payload }) {
  const wrapperRef = useRef(null);
  const renders = useRef(0);
  const [wire, setWire] = useState({ props: "not present", diff: "not present" });
  renders.current += 1;

  useEffect(() => {
    const wrapper = wrapperRef.current?.closest("[data-props]");
    if (!wrapper) return;

    setWire({
      props: describeAttr(wrapper.getAttribute("data-props")),
      diff: describeAttr(wrapper.getAttribute("data-props-diff")),
    });
  }, [payload]);

  return (
    <div ref={wrapperRef} className="rounded-md border p-4">
      <h3 className="font-medium">{label}</h3>
      <dl className="mt-2 grid grid-cols-2 gap-x-4 text-sm">
        <dt className="text-muted-foreground">counter</dt>
        <dd>{payload.counter}</dd>
        <dt className="text-muted-foreground">renders</dt>
        <dd>{renders.current}</dd>
        <dt className="text-muted-foreground">data-props</dt>
        <dd>{wire.props}</dd>
        <dt className="text-muted-foreground">data-props-diff</dt>
        <dd>{wire.diff}</dd>
      </dl>
    </div>
  );
}
