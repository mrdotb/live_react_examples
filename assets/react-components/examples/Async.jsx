import React from "react";

export function Async({ stats }) {
  if (stats.loading) {
    return <p className="text-sm text-muted-foreground">Loading…</p>;
  }

  if (stats.failed) {
    return <p className="text-sm text-destructive">Failed: {String(stats.failed)}</p>;
  }

  return (
    <dl className="grid grid-cols-2 gap-x-4 text-sm">
      <dt className="text-muted-foreground">stars</dt>
      <dd>{stats.result.stars}</dd>
      <dt className="text-muted-foreground">downloads</dt>
      <dd>{stats.result.downloads}</dd>
    </dl>
  );
}
