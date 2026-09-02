import React from "react";

export function Encoder({ user }) {
  return (
    <dl className="grid grid-cols-2 gap-x-4 text-sm">
      <dt className="text-muted-foreground">name</dt>
      <dd>{user.name}</dd>
      <dt className="text-muted-foreground">email</dt>
      <dd>{user.email}</dd>
    </dl>
  );
}
