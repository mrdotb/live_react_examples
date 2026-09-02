import * as React from "react";
import { useState } from "react";
import { DualRangeSlider } from "../ui/dual-range-slider";
import { Label } from "../ui/label";

function formatMilliseconds(ms) {
  const seconds = Math.floor(ms / 1000) % 60;
  const minutes = Math.floor(ms / (1000 * 60)) % 60;
  const hours = Math.floor(ms / (1000 * 60 * 60));

  const parts = [];
  if (hours > 0) parts.push(`${hours}h`);
  if (minutes > 0) parts.push(`${minutes}m`);
  if (seconds > 0 || parts.length === 0) parts.push(`${seconds}s`);

  return parts.join("");
}

// A LiveView form field, wired up like any other React control: it doesn't
// call pushEvent itself. `inputName` gives Radix's slider the field name
// Phoenix.HTML.Form expects, so the value reaches phx-change like a normal
// form field would.
export function HybridForm({ inputName, value, min, max, step }) {
  const [values, setValues] = useState(value);

  return (
    <div className="flex w-full flex-col space-y-8">
      <Label>Delay between</Label>
      <DualRangeSlider
        name={inputName}
        label={(v) => <span>{formatMilliseconds(v ?? 0)}</span>}
        value={values}
        onValueChange={setValues}
        min={min}
        max={max}
        step={step}
      />
    </div>
  );
}
