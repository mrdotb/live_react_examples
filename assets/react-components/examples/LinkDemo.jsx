import React from "react";
import { Link } from "live_react";

export function LinkDemo({ currentPath, mountCount, paramsUpdateCount }) {
  return (
    <div className="flex flex-col gap-4">
      <dl className="grid grid-cols-2 gap-x-4 gap-y-1 text-sm">
        <dt className="text-muted-foreground">Current path</dt>
        <dd>
          <code>{currentPath}</code>
        </dd>
        <dt className="text-muted-foreground">Mount count</dt>
        <dd>{mountCount}</dd>
        <dt className="text-muted-foreground">Params update count</dt>
        <dd>{paramsUpdateCount}</dd>
      </dl>

      <div className="flex gap-3">
        {/* Same route, same query shape, different navigation mode — the
            only thing that varies is patch vs navigate, so any difference
            in the counts above is caused by that alone. */}
        <Link patch="/examples/link-demo?visited=patch" className="rounded-md border px-3 py-1">
          patch (same process, no remount)
        </Link>
        <Link
          navigate="/examples/link-demo?visited=navigate"
          className="rounded-md border px-3 py-1"
        >
          navigate (fresh mount, same process)
        </Link>
      </div>
    </div>
  );
}
