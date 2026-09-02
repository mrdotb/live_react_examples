import React, { useState } from "react";
import { useLiveReact } from "live_react";

export function Counter({ count }) {
  const { pushEvent } = useLiveReact();
  const [step, setStep] = useState(1);

  return (
    <div className="flex items-center gap-4">
      <button
        className="rounded-md border px-3 py-1"
        onClick={() => pushEvent("set_count", { value: count - step })}
      >
        −{step}
      </button>

      <span className="min-w-16 text-center text-2xl font-semibold">{count}</span>

      <button
        className="rounded-md border px-3 py-1"
        onClick={() => pushEvent("set_count", { value: count + step })}
      >
        +{step}
      </button>

      {/* step lives only in React — the server never sees it */}
      <label className="ml-4 flex items-center gap-2 text-sm">
        step
        <input
          type="range"
          min="1"
          max="10"
          value={step}
          onChange={(e) => setStep(Number(e.target.value))}
        />
        {step}
      </label>
    </div>
  );
}
