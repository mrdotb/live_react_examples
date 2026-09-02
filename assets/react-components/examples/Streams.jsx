import { useState } from "react";
import { useLiveReact } from "live_react";

export function Streams({ messages = [] }) {
  const { pushEvent } = useLiveReact();
  const [draft, setDraft] = useState("");
  const [editingId, setEditingId] = useState(null);
  const [editText, setEditText] = useState("");

  const send = (e) => {
    e.preventDefault();
    if (!draft.trim()) return;
    pushEvent("add", { text: draft });
    setDraft("");
  };

  const startEditing = (message) => {
    setEditingId(message.id);
    setEditText(message.text);
  };

  const saveEdit = (e) => {
    e.preventDefault();
    pushEvent("edit", { id: editingId, text: editText });
    setEditingId(null);
  };

  return (
    <div className="flex flex-col gap-3">
      <div className="flex gap-2">
        <form className="flex gap-2" onSubmit={send}>
          <input
            type="text"
            value={draft}
            placeholder="say something…"
            onChange={(e) => setDraft(e.target.value)}
            className="rounded-md border px-2 py-1"
          />
          <button type="submit" className="rounded-md border px-3 py-1">
            Send
          </button>
        </form>

        <button
          type="button"
          className="rounded-md border px-3 py-1"
          onClick={() => pushEvent("replace_all", {})}
        >
          Replace all
        </button>
      </div>

      <ul className="flex flex-col gap-1">
        {messages.map((message) => (
          // `__dom_id` is added by LiveReact for every stream item — a
          // stable id derived from Phoenix's own stream ref, safe to use as
          // the React key even across inserts, deletes and resets.
          <li
            key={message.__dom_id}
            className="flex items-center justify-between border-t border-[#eee] py-1"
          >
            {editingId === message.id ? (
              <form className="flex grow gap-2" onSubmit={saveEdit}>
                <input
                  type="text"
                  value={editText}
                  autoFocus
                  onChange={(e) => setEditText(e.target.value)}
                  className="grow rounded-md border px-2 py-1"
                />
                <button type="submit" className="rounded-md border px-2 py-0.5 text-sm">
                  Save
                </button>
              </form>
            ) : (
              <>
                <span>{message.text}</span>
                <span className="flex gap-2">
                  <button
                    type="button"
                    className="rounded-md border px-2 py-0.5 text-sm"
                    onClick={() => startEditing(message)}
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    className="rounded-md border px-2 py-0.5 text-sm"
                    onClick={() => pushEvent("delete", { id: message.id })}
                  >
                    Delete
                  </button>
                </span>
              </>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}
