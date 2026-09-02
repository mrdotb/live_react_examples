import React, { useState } from "react";
import { useLiveReact } from "live_react";

export function Events({ items }) {
  const { pushEvent } = useLiveReact();
  const [body, setBody] = useState("");

  const addItem = (e) => {
    e.preventDefault();
    if (!body.trim()) return;
    pushEvent("add_item", { body });
    setBody("");
  };

  return (
    <div className="flex flex-col gap-3">
      <form className="flex gap-2" onSubmit={addItem}>
        <input
          type="text"
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="say something…"
          className="rounded-md border px-2 py-1"
        />
        <button type="submit" className="rounded-md border px-3 py-1">
          Add item
        </button>
      </form>

      <ul className="flex flex-col gap-1 text-sm">
        {items.map((item) => (
          <li key={item.id} className="border-t border-[#eee] py-1">
            {item.body}
          </li>
        ))}
      </ul>
    </div>
  );
}
