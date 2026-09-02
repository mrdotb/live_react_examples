import React, { useState } from "react";
import hljs from "highlight.js/lib/core";
import elixir from "highlight.js/lib/languages/elixir";
import javascript from "highlight.js/lib/languages/javascript";
import typescript from "highlight.js/lib/languages/typescript";
import erb from "highlight.js/lib/languages/erb";

hljs.registerLanguage("elixir", elixir);
hljs.registerLanguage("jsx", javascript);
hljs.registerLanguage("tsx", typescript);
hljs.registerLanguage("heex", erb);

// The duotone convention from the design system: anything that runs on the
// server is brand orange, anything that runs in the browser is React cyan.
const SIDE = {
  server: "border-[color:var(--color-brand)] text-[color:var(--color-brand)]",
  client: "border-[color:var(--color-client)] text-[color:var(--color-client)]",
};

export function CodeBlock({ code, language, filename, side = "server" }) {
  const [copied, setCopied] = useState(false);

  // hljs throws on an unregistered language; fall back to plain text rather
  // than taking the whole page down over a typo in a language name.
  let html;
  try {
    html = hljs.highlight(code, { language }).value;
  } catch {
    html = code.replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" })[c]);
  }

  const copy = () => {
    navigator.clipboard?.writeText(code).then(
      () => {
        setCopied(true);
        setTimeout(() => setCopied(false), 1500);
      },
      () => {},
    );
  };

  return (
    <div className="overflow-hidden rounded-lg border border-[color:var(--edge)]">
      <div
        className={`flex items-center justify-between border-b-2 bg-[color:var(--surface-raised)] px-4 py-2 text-xs font-medium ${SIDE[side] ?? SIDE.server}`}
      >
        <span>{filename}</span>
        <button
          type="button"
          onClick={copy}
          className="rounded px-2 py-1 text-[color:var(--text-muted)] hover:text-[color:var(--text)]"
        >
          {copied ? "copied" : "copy"}
        </button>
      </div>

      <pre className="overflow-x-auto bg-[color:var(--surface-raised)] p-4 text-sm">
        <code dangerouslySetInnerHTML={{ __html: html }} />
      </pre>
    </div>
  );
}
