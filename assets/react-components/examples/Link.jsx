import React from "react";
import { Link } from "live_react";

// Real JSX usage of `Link`, the drop-in `<a>` replacement exported by
// `live_react`. `href` is a plain anchor — a full browser navigation, no
// LiveView involved at all — while `navigate` changes the URL and mounts a
// new root LiveView over the existing socket, with no full page reload.
//
// Named `LinkExample`, not `Link`: this file already imports the real
// `Link` from `live_react` above, so exporting a component under the same
// name would shadow it.
export function LinkExample() {
  return (
    <div className="flex gap-3">
      <Link href="/examples/counter" className="rounded-md border px-3 py-1">
        href — full page reload
      </Link>
      <Link navigate="/examples/context" className="rounded-md border px-3 py-1">
        navigate — same process, no reload
      </Link>
    </div>
  );
}
