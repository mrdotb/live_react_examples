import React from "react";
import { useLiveReact } from "live_react";

export function FileUpload({ avatar, uploaded_names = [] }) {
  const { upload, pushEvent } = useLiveReact();

  const handleChange = (e) => {
    if (e.target.files.length > 0) {
      upload("avatar", e.target.files);
    }
  };

  return (
    <div className="space-y-3">
      <input type="file" accept={avatar.accept} multiple onChange={handleChange} />

      <ul className="space-y-1 text-sm">
        {avatar.entries.map((entry) => (
          <li key={entry.ref} className="flex items-center gap-2">
            <span>{entry.client_name}</span>
            <progress value={entry.progress} max="100" />
            <span className="text-muted-foreground">{entry.progress}%</span>
          </li>
        ))}
      </ul>

      <button
        type="button"
        className="rounded-md border px-3 py-1"
        disabled={avatar.entries.length === 0}
        onClick={() => pushEvent("submit", {})}
      >
        Submit
      </button>

      {uploaded_names.length > 0 && (
        <p className="text-sm text-muted-foreground">
          Server received (and discarded): {uploaded_names.join(", ")}
        </p>
      )}
    </div>
  );
}
