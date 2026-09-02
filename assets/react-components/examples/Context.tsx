import React, { createContext, useContext } from "react";
import { useLiveReact } from "live_react";

// `count` comes from the server, but only the provider at the top needs to
// know that — everything below reads it from context, with no prop drilling.
const CountContext = createContext<number>(0);

function CountDisplay() {
  const count = useContext(CountContext);
  return <span className="text-xl">{count}</span>;
}

export function Context({ count }: { count: number }) {
  const { pushEvent } = useLiveReact();

  return (
    <CountContext.Provider value={count}>
      <div className="flex items-center gap-6">
        <button
          className="rounded-md border px-3 py-1"
          onClick={() => pushEvent("set_count", { value: count - 1 })}
        >
          −1
        </button>
        <CountDisplay />
        <button
          className="rounded-md border px-3 py-1"
          onClick={() => pushEvent("set_count", { value: count + 1 })}
        >
          +1
        </button>
      </div>
    </CountContext.Provider>
  );
}
