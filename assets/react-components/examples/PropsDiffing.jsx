import React, { useEffect, useRef, useState } from "react";

// Reports how many bytes actually crossed the wire on the last update.
//
// Measuring the *size* of `data-props` is misleading: on a diffed component
// that attribute holds the first snapshot and never changes again — which is
// the whole point of diffing — so both a diffed and an undiffed instance show
// roughly the same number while meaning completely different things. What
// distinguishes them is which attribute *changed*, and how big it was.
//
// So this keeps the previous value of both attributes and diffs them itself.
// The numbers below are measured from the real wire payload, never computed
// from the props.
const bytes = (value) => new TextEncoder().encode(value).length;

export function PropsDiffing({ label, payload }) {
  const wrapperRef = useRef(null);
  const previous = useRef(null);
  const [wire, setWire] = useState({
    status: "waiting for the first update",
    last: null,
    total: 0,
    source: null,
  });

  useEffect(() => {
    const wrapper = wrapperRef.current?.closest("[data-props]");
    if (!wrapper) return;

    const current = {
      props: wrapper.getAttribute("data-props") ?? "",
      diff: wrapper.getAttribute("data-props-diff") ?? "",
    };

    // First observation is the initial render, where everything is new by
    // definition. Counting it would flatter whichever instance happened to
    // render first, so it is recorded and excluded.
    if (previous.current === null) {
      previous.current = current;
      setWire((w) => ({ ...w, status: "initial render (not counted)" }));
      return;
    }

    const changed = [];
    let size = 0;

    if (current.props !== previous.current.props) {
      changed.push("data-props");
      size += bytes(current.props);
    }

    if (current.diff !== previous.current.diff) {
      changed.push("data-props-diff");
      size += bytes(current.diff);
    }

    previous.current = current;

    setWire((w) => ({
      status: changed.length ? "updated" : "no attribute changed",
      last: size,
      total: w.total + size,
      source: changed.join(" + ") || null,
    }));
  }, [payload]);

  return (
    <div ref={wrapperRef} className="rounded-md border border-[color:var(--edge)] p-4">
      <h3 className="font-medium">{label}</h3>

      <dl className="mt-2 grid grid-cols-[auto_1fr] gap-x-4 text-sm">
        <dt className="text-[color:var(--text-muted)]">counter</dt>
        <dd>{payload.counter}</dd>

        <dt className="text-[color:var(--text-muted)]">last update</dt>
        <dd>{wire.last === null ? wire.status : `${wire.last} bytes`}</dd>

        <dt className="text-[color:var(--text-muted)]">via</dt>
        <dd>{wire.source ?? "—"}</dd>

        <dt className="text-[color:var(--text-muted)]">total received</dt>
        <dd>{wire.total} bytes</dd>
      </dl>
    </div>
  );
}
