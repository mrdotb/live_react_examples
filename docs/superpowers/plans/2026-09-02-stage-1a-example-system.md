# Stage 1a — Example System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the machinery that shows an example's real source code, and prove it end to end on one migrated example — replacing the runtime GitHub fetch that has been returning 404 since the examples app moved to its own repo.

**Architecture:** A registry module is the single source of truth for every example's metadata. Compile-time macros read each example's preview module and React component off disk with `@external_resource`, so the code shown is provably the code running and can never drift. A shared `example_page/1` component owns all the page chrome, so each example module is ~30 lines. The code viewer is itself a React component rendered through LiveReact's SSR, so the site dogfoods the library on every example page.

**Tech Stack:** Elixir 1.20 / Phoenix LiveView 1.2, LiveReact 2.0, React 19, Tailwind 4, highlight.js, Vite 7.

**Spec:** `docs/superpowers/specs/2026-09-01-site-redesign-design.md` (Stage 1 section)

## Global Constraints

- Branch: `stage-1-examples`, based on the completed Stage 0 work.
- No new hex dependency. `highlight.js` is already an npm dependency and is the only highlighter; do not add another.
- **Every existing route must keep working after every task.** `/simple`, `/live-counter`, `/log-list`, `/flash-sonner`, `/ssr`, `/hybrid-form`, `/slot`, `/context`, `/link-demo`, `/link-usage`, `/stream-demo`, `/simple-props`, `/typescript`, `/lazy` all still serve. Stage 1b migrates them; this stage only *adds*.
- `mix test`, `mix format --check-formatted` and `mix compile --force --warnings-as-errors` pass before every commit.
- Do NOT delete `lib/live_react_examples.ex`, `assets/react-components/github-code.jsx`, the `demo/1` component, or `LiveDemoAssigns` — the 13 unmigrated examples still depend on all four. Stage 1b removes them.
- **SSR config is split by environment and must stay that way.** `assets/vite.config.js` keeps React external in dev (Vite's dev module runner evaluates inlined modules as ESM and `react/jsx-dev-runtime` is CJS) and bundles everything for the build (production runs `server.js` under Node with nothing reachable from `priv/`). Do not collapse the two branches. `test/ssr_bundle_test.exs` guards the build half.
- Dev server is port 3200, Vite 3300.
- Semantic CSS tokens available from Stage 0: `--surface`, `--surface-raised`, `--text`, `--text-muted`, `--edge`, plus `--color-brand` (`#FD4F00`, server side) and `--color-client` (`#61DAFB`, client side). Use the duotone convention — Elixir/LiveView surfaces are brand-orange, React surfaces are client-cyan.

---

### Task 1: The example registry

Single source of truth. Nav, index, prev/next links, routes and tests all derive from this, so it lands first and alone.

**Files:**
- Create: `lib/live_react_examples/examples.ex`
- Test: `test/live_react_examples/examples_test.exs`

**Interfaces:**
- Consumes: nothing.
- Produces: `LiveReactExamples.Examples` with `all/0` → list of example maps in display order; `by_category/0` → `[%{category: String.t(), items: [map]}]`; `fetch/1` → `{:ok, map} | :error` by slug; `neighbours/1` → `{prev, next}` where each is a map or `nil`; `ready/0` → only examples with `status: :ready`. Every example map has keys `:id, :title, :description, :icon, :kind, :module, :features, :status`.

- [ ] **Step 1: Write the failing test**

Create `test/live_react_examples/examples_test.exs`:

```elixir
defmodule LiveReactExamples.ExamplesTest do
  use ExUnit.Case, async: true

  alias LiveReactExamples.Examples

  test "every example has the keys the page and nav depend on" do
    for example <- Examples.all() do
      for key <- [:id, :title, :description, :icon, :kind, :module, :features, :status] do
        assert Map.has_key?(example, key), "#{example[:id] || "?"} is missing #{key}"
      end

      assert example.kind in [:live, :dead], "#{example.id} has bad kind #{inspect(example.kind)}"
      assert example.status in [:ready, :planned]
      assert is_list(example.features) and example.features != []
    end
  end

  test "slugs are unique and url-safe" do
    ids = Enum.map(Examples.all(), & &1.id)
    assert ids == Enum.uniq(ids)

    for id <- ids do
      assert id =~ ~r/^[a-z0-9-]+$/, "#{id} is not a url-safe slug"
    end
  end

  test "fetch finds by slug and reports misses" do
    assert {:ok, counter} = Examples.fetch("counter")
    assert counter.title == "Counter"
    assert :error = Examples.fetch("does-not-exist")
  end

  test "by_category preserves display order and loses nothing" do
    flattened = Examples.by_category() |> Enum.flat_map(& &1.items)
    assert flattened == Examples.all()
  end

  test "neighbours walks the flat order, nil at the ends" do
    [first | _] = all = Examples.all()
    last = List.last(all)

    assert {nil, second} = Examples.neighbours(first.id)
    assert second == Enum.at(all, 1)

    assert {before_last, nil} = Examples.neighbours(last.id)
    assert before_last == Enum.at(all, -2)
  end

  test "ready/0 is the subset that has routes" do
    assert Enum.all?(Examples.ready(), &(&1.status == :ready))
    assert "counter" in Enum.map(Examples.ready(), & &1.id)
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples/examples_test.exs`
Expected: FAIL — `LiveReactExamples.Examples` is undefined.

- [ ] **Step 3: Write the registry**

Create `lib/live_react_examples/examples.ex`. Note `status`: only `:ready` examples get routes. In this stage `counter` alone is `:ready` — Stage 1b flips the rest as it migrates them, and Stage 1c adds the four new ones.

```elixir
defmodule LiveReactExamples.Examples do
  @moduledoc """
  Catalog of every LiveReact example.

  The single source of truth: the sidebar, the index page, the router, the
  prev/next footer and the tests all derive from this list, so adding an
  example means adding one entry here plus its two source files.

  `kind` distinguishes the two ways LiveReact is used, which is itself one of
  the things the site demonstrates:

    * `:live` — the preview is a LiveView, rendered as a child via
      `live_render/3`.
    * `:dead` — the preview is a controller-rendered page with no socket. The
      point of these examples is that React works without a LiveView, so they
      are rendered inline and offered as a standalone route rather than being
      wrapped in a LiveView, which would destroy what they demonstrate.

  `status` is `:ready` when the example has been migrated to the two-module
  convention and has a route. `:planned` entries appear in the index greyed
  out and have no route.
  """

  @examples [
    %{
      category: "Getting Started",
      items: [
        %{
          id: "counter",
          title: "Counter",
          description: "Assigns become props; clicks become handle_event",
          icon: "hero-plus-circle",
          kind: :live,
          module: "Counter",
          features: ["props", "phx-click", "local state"],
          status: :ready
        },
        %{
          id: "simple",
          title: "Hello React",
          description: "Render a component from a controller, with no socket",
          icon: "hero-sparkles",
          kind: :dead,
          module: "Simple",
          features: ["dead view", "SSR"],
          status: :planned
        },
        %{
          id: "simple-props",
          title: "Props",
          description: "Pass values from a template into a component",
          icon: "hero-arrow-right-circle",
          kind: :dead,
          module: "SimpleProps",
          features: ["dead view", "props"],
          status: :planned
        }
      ]
    },
    %{
      category: "Events",
      items: [
        %{
          id: "events",
          title: "Event Handling",
          description: "pushEvent from React reaches handle_event on the server",
          icon: "hero-cursor-arrow-rays",
          kind: :live,
          module: "Events",
          features: ["useLiveReact", "pushEvent"],
          status: :planned
        },
        %{
          id: "server-events",
          title: "Server Events",
          description: "push_event on the server reaches handleEvent in React",
          icon: "hero-bell-alert",
          kind: :live,
          module: "ServerEvents",
          features: ["push_event", "handleEvent", "toasts"],
          status: :planned
        }
      ]
    },
    %{
      category: "Props & data",
      items: [
        %{
          id: "streams",
          title: "Phoenix Streams",
          description: "A stream assign arrives in React as an array with __dom_id",
          icon: "hero-signal",
          kind: :live,
          module: "Streams",
          features: ["stream/4", "__dom_id"],
          status: :planned
        }
      ]
    },
    %{
      category: "Forms",
      items: [
        %{
          id: "hybrid-form",
          title: "Hybrid Form",
          description: "A LiveView form with a React control inside it",
          icon: "hero-adjustments-horizontal",
          kind: :live,
          module: "HybridForm",
          features: ["forms", "Phoenix.HTML.Form encoder"],
          status: :planned
        }
      ]
    },
    %{
      category: "Navigation",
      items: [
        %{
          id: "link",
          title: "Link",
          description: "The Link component for href, patch and navigate",
          icon: "hero-link",
          kind: :live,
          module: "Link",
          features: ["Link", "patch", "navigate"],
          status: :planned
        },
        %{
          id: "link-demo",
          title: "Patch vs Navigate",
          description: "What each navigation mode actually does to the socket",
          icon: "hero-arrows-right-left",
          kind: :live,
          module: "LinkDemo",
          features: ["Link", "handle_params"],
          status: :planned
        }
      ]
    },
    %{
      category: "Advanced",
      items: [
        %{
          id: "ssr",
          title: "SSR Control",
          description: "Turn server rendering off for browser-only components",
          icon: "hero-server",
          kind: :live,
          module: "SSR",
          features: ["ssr={false}"],
          status: :planned
        },
        %{
          id: "slots",
          title: "Slots",
          description: "HEEx markup passed into React as children",
          icon: "hero-puzzle-piece",
          kind: :live,
          module: "Slots",
          features: ["inner_block", "children"],
          status: :planned
        },
        %{
          id: "context",
          title: "React Context",
          description: "Share state between components without prop drilling",
          icon: "hero-share",
          kind: :live,
          module: "Context",
          features: ["context", "local state"],
          status: :planned
        },
        %{
          id: "typescript",
          title: "TypeScript",
          description: "Typed props in a .tsx component",
          icon: "hero-code-bracket",
          kind: :dead,
          module: "Typescript",
          features: ["dead view", "TypeScript"],
          status: :planned
        },
        %{
          id: "lazy",
          title: "Lazy Loading",
          description: "React.lazy and Suspense inside LiveView",
          icon: "hero-clock",
          kind: :dead,
          module: "Lazy",
          features: ["dead view", "React.lazy", "Suspense"],
          status: :planned
        }
      ]
    }
  ]

  @flat Enum.flat_map(@examples, & &1.items)

  @doc "Every example, in display order."
  def all, do: @flat

  @doc "Examples grouped into their categories, in display order."
  def by_category, do: @examples

  @doc "Only the examples that have been migrated and have a route."
  def ready, do: Enum.filter(@flat, &(&1.status == :ready))

  @doc "Looks an example up by slug."
  def fetch(id) do
    case Enum.find(@flat, &(&1.id == id)) do
      nil -> :error
      example -> {:ok, example}
    end
  end

  @doc """
  The examples either side of `id` in display order, for the prev/next footer.
  Returns `{nil, next}` at the start and `{prev, nil}` at the end.
  """
  def neighbours(id) do
    index = Enum.find_index(@flat, &(&1.id == id))

    case index do
      nil -> {nil, nil}
      0 -> {nil, Enum.at(@flat, 1)}
      i -> {Enum.at(@flat, i - 1), Enum.at(@flat, i + 1)}
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mix test test/live_react_examples/examples_test.exs`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/live_react_examples/examples.ex test/live_react_examples/examples_test.exs
git commit -m "feat: example registry as the single source of truth"
```

---

### Task 2: Compile-time source embedding

Replaces the runtime `raw.githubusercontent.com` fetch. Reads source off disk at compile time and rewrites it so visitors see copy-pasteable `MyAppWeb` code.

**Files:**
- Create: `lib/live_react_examples_web/examples/example_source.ex`
- Create: `lib/live_react_examples_web/examples/counter_preview.ex`
- Create: `assets/react-components/examples/Counter.jsx`
- Test: `test/live_react_examples_web/examples/example_source_test.exs`

**Interfaces:**
- Consumes: nothing.
- Produces: `LiveReactExamplesWeb.Examples.ExampleSource` with two macros — `elixir_source(name)` reads `lib/live_react_examples_web/examples/{snake}_preview.ex` and returns a rewritten `String.t()`; `react_source(name)` reads `assets/react-components/examples/{name}.jsx` (falling back to `.tsx`) and returns it verbatim. Both register `@external_resource`.

- [ ] **Step 1: Write the failing test**

Create `test/live_react_examples_web/examples/example_source_test.exs`:

```elixir
defmodule LiveReactExamplesWeb.Examples.ExampleSourceTest do
  @moduledoc """
  The point of embedding source at compile time is that what a visitor reads
  is provably what runs. These tests pin the rewriting so the displayed code
  stays copy-pasteable into someone else's app.
  """
  use ExUnit.Case, async: true

  require LiveReactExamplesWeb.Examples.ExampleSource, as: ExampleSource

  @elixir ExampleSource.elixir_source("Counter")
  @react ExampleSource.react_source("Counter")

  test "the elixir source is rewritten to look like a generic app" do
    refute @elixir =~ "LiveReactExamplesWeb"
    refute @elixir =~ "Preview"
    assert @elixir =~ "MyAppWeb.CounterLive"
  end

  test "site-only noise is stripped" do
    refute @elixir =~ "@moduledoc"
    refute @elixir =~ "layout: false"
    refute @elixir =~ "examples/Counter"
    assert @elixir =~ ~s(name="Counter")
  end

  test "the rewritten elixir source is still valid elixir" do
    assert {:ok, _ast} = Code.string_to_quoted(@elixir)
  end

  test "the elixir source is the real module, not a stub" do
    assert @elixir =~ "def mount"
    assert @elixir =~ "def render"
    assert @elixir =~ "handle_event"
  end

  test "the react source is returned verbatim" do
    assert @react =~ "export function Counter"
    assert @react =~ "useLiveReact"
  end

  test "a missing example fails loudly at compile time" do
    assert_raise File.Error, fn ->
      Code.eval_string("""
      require LiveReactExamplesWeb.Examples.ExampleSource, as: ES
      ES.react_source("NoSuchComponent")
      """)
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples_web/examples/example_source_test.exs`
Expected: FAIL — the module does not exist.

- [ ] **Step 3: Write the React component**

Create `assets/react-components/examples/Counter.jsx`. Keep it minimal — this file's *source* is the documentation, so no page chrome and no cleverness:

```jsx
import React, { useState } from "react";
import { useLiveReact } from "live_react";

export function Counter({ count }) {
  const { pushEvent } = useLiveReact();
  const [step, setStep] = useState(1);

  return (
    <div className="flex items-center gap-4">
      <button
        className="rounded-md border px-3 py-1"
        onClick={() => pushEvent("set_count", { value: count - step })}
      >
        −{step}
      </button>

      <span className="min-w-16 text-center text-2xl font-semibold">{count}</span>

      <button
        className="rounded-md border px-3 py-1"
        onClick={() => pushEvent("set_count", { value: count + step })}
      >
        +{step}
      </button>

      {/* step lives only in React — the server never sees it */}
      <label className="ml-4 flex items-center gap-2 text-sm">
        step
        <input
          type="range"
          min="1"
          max="10"
          value={step}
          onChange={(e) => setStep(Number(e.target.value))}
        />
        {step}
      </label>
    </div>
  );
}
```

Register it in `assets/react-components/index.jsx` — add the import alongside the existing ones and the key to the default export. The component name registered must be `Counter`, but the existing `./counter` export is also named `Counter`, so import this one with an alias and register the alias under a distinct key:

```js
import { Counter as ExampleCounter } from "./examples/Counter";
```

and in the default export object add:

```js
  "examples/Counter": ExampleCounter,
```

Using the path-style key keeps the migrated examples namespaced and avoids colliding with the 13 unmigrated components while both exist.

- [ ] **Step 4: Write the preview module**

Create `lib/live_react_examples_web/examples/counter_preview.ex`. This module's own source is what the "LiveView" tab displays, so it stays minimal:

```elixir
defmodule LiveReactExamplesWeb.Examples.CounterPreview do
  @moduledoc """
  Minimal working Counter. This module's source is displayed verbatim on the
  example page, so it deliberately contains no page chrome.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0), layout: false}
  end

  def render(assigns) do
    ~H"""
    <.react name="examples/Counter" count={@count} socket={@socket} />
    """
  end

  def handle_event("set_count", %{"value" => value}, socket) do
    {:noreply, assign(socket, :count, value)}
  end
end
```

- [ ] **Step 5: Write the macros**

Create `lib/live_react_examples_web/examples/example_source.ex`:

```elixir
defmodule LiveReactExamplesWeb.Examples.ExampleSource do
  @moduledoc """
  Reads example source off disk at compile time.

  This replaces fetching source from raw.githubusercontent.com at runtime,
  which broke silently when the examples app moved to its own repository and
  left every code tab showing an empty block. Reading at compile time means
  the code a visitor sees is provably the code that runs, needs no network,
  and appears in the server-rendered HTML.

  Both macros register the file as an `@external_resource`, so editing an
  example recompiles the page that displays it.
  """

  @doc """
  The preview module's source, rewritten to look like ordinary application
  code: `LiveReactExamplesWeb.Examples.CounterPreview` becomes
  `MyAppWeb.CounterLive`, the `examples/` component prefix is dropped, and the
  `@moduledoc` and `layout: false` that exist only for this site are stripped.
  """
  defmacro elixir_source(name) do
    quote bind_quoted: [name: name] do
      path =
        Path.join([
          File.cwd!(),
          "lib/live_react_examples_web/examples",
          "#{Macro.underscore(name)}_preview.ex"
        ])

      @external_resource path

      path
      |> File.read!()
      |> String.replace("LiveReactExamplesWeb.Examples.#{name}Preview", "MyAppWeb.#{name}Live")
      |> String.replace("LiveReactExamplesWeb", "MyAppWeb")
      |> String.replace(~s(name="examples/), ~s(name="))
      |> strip_moduledoc()
      |> String.replace(", layout: false", "")
      |> String.trim()
    end
  end

  @doc """
  The React component's source, verbatim. Tries `.jsx` then `.tsx`.
  """
  defmacro react_source(name) do
    quote bind_quoted: [name: name] do
      dir = Path.join([File.cwd!(), "assets/react-components/examples"])
      jsx = Path.join(dir, "#{name}.jsx")
      tsx = Path.join(dir, "#{name}.tsx")
      path = if File.exists?(jsx), do: jsx, else: tsx

      @external_resource path

      File.read!(path)
    end
  end
end
```

`strip_moduledoc/1` is a plain public function on the same module rather than an
inline regex, because a heredoc-matching regex inside a `quote` block is easy to
get wrong and impossible to test in isolation. Add it below the macros:

```elixir
  @doc """
  Removes a heredoc `@moduledoc` block.

  Kept as a function, not an inline regex in the macro, so it can be tested
  directly — an over-greedy match here silently truncates the displayed source.
  """
  def strip_moduledoc(source) do
    String.replace(source, ~r/\s*@moduledoc\s+"""(?:.*?)"""\R?/s, "\n")
  end
```

Add a direct test for it in the same test file:

```elixir
  test "strip_moduledoc removes only the moduledoc, not the code after it" do
    source = """
    defmodule Thing do
      @moduledoc \"\"\"
      Explanatory prose with a stray \"\"\" nowhere near.
      \"\"\"
      def keep_me, do: :ok
    end
    """

    stripped = LiveReactExamplesWeb.Examples.ExampleSource.strip_moduledoc(source)

    refute stripped =~ "Explanatory prose"
    assert stripped =~ "def keep_me"
    assert stripped =~ "defmodule Thing"
  end
```

- [ ] **Step 6: Run test to verify it passes**

Run: `mix test test/live_react_examples_web/examples/example_source_test.exs`
Expected: PASS, 6 tests. If "the rewritten elixir source is still valid elixir" fails, the moduledoc regex has eaten too much — check it against the actual file.

- [ ] **Step 7: Verify recompilation actually triggers**

```bash
mix compile
touch lib/live_react_examples_web/examples/counter_preview.ex
mix compile
```

Expected: the second `mix compile` reports recompiling the test/consumer module too, proving `@external_resource` is wired. Note this in your report.

- [ ] **Step 8: Commit**

```bash
git add lib/live_react_examples_web/examples/ assets/react-components/examples/ \
        assets/react-components/index.jsx \
        test/live_react_examples_web/examples/example_source_test.exs
git commit -m "feat: embed example source at compile time"
```

---

### Task 3: The CodeBlock component

The code viewer is itself a React component rendered through LiveReact's SSR, so highlighted source is in the initial HTML and the site demonstrates the library on every example page.

**Files:**
- Create: `assets/react-components/examples/CodeBlock.jsx`
- Modify: `assets/react-components/index.jsx`
- Test: `test/live_react_examples_web/examples/code_block_test.exs`

**Interfaces:**
- Consumes: nothing.
- Produces: a React component registered as `examples/CodeBlock`, taking props `code` (string), `language` (`"elixir"` | `"jsx"` | `"tsx"` | `"heex"`), `filename` (string), `side` (`"server"` | `"client"`). Rendered from HEEx as `<.react name="examples/CodeBlock" code={...} language="elixir" filename="counter_live.ex" side="server" />`.

- [ ] **Step 1: Write the failing test**

Create `test/live_react_examples_web/examples/code_block_test.exs`:

```elixir
defmodule LiveReactExamplesWeb.Examples.CodeBlockTest do
  @moduledoc """
  CodeBlock is rendered through LiveReact's SSR so that source appears in the
  initial HTML — for search engines, for no-JS readers, and because it makes
  every example page a live demonstration of the library.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "server-renders the code into the initial HTML" do
    html =
      render_component(&LiveReact.react/1,
        name: "examples/CodeBlock",
        code: "def hello, do: :world",
        language: "elixir",
        filename: "hello.ex",
        side: "server"
      )

    assert html =~ "hello.ex"
    assert html =~ "hello"
    assert html =~ "world"
  end

  test "the props reach the component" do
    html =
      render_component(&LiveReact.react/1,
        name: "examples/CodeBlock",
        code: "const a = 1",
        language: "jsx",
        filename: "thing.jsx",
        side: "client"
      )

    props = LiveReact.Test.get_react(html, name: "examples/CodeBlock").props

    assert props["code"] == "const a = 1"
    assert props["language"] == "jsx"
    assert props["filename"] == "thing.jsx"
    assert props["side"] == "client"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples_web/examples/code_block_test.exs`
Expected: FAIL — the component is not registered, so SSR raises.

- [ ] **Step 3: Write the component**

Create `assets/react-components/examples/CodeBlock.jsx`. Register only the four languages actually used, so the SSR bundle does not carry all of highlight.js:

```jsx
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
```

Register it in `assets/react-components/index.jsx`:

```js
import { CodeBlock } from "./examples/CodeBlock";
```

and add `"examples/CodeBlock": CodeBlock,` to the default export.

- [ ] **Step 4: Run test to verify it passes**

Run: `mix test test/live_react_examples_web/examples/code_block_test.exs`
Expected: PASS, 2 tests.

- [ ] **Step 5: Confirm the SSR bundle still resolves standalone**

Adding highlight.js to the SSR path grows the bundle. Confirm the production contract still holds:

Run: `mix test test/ssr_bundle_test.exs --include assets`
Expected: PASS, 2 tests. Report the new `priv/react-components/server.js` size.

- [ ] **Step 6: Commit**

```bash
git add assets/react-components/examples/CodeBlock.jsx assets/react-components/index.jsx \
        test/live_react_examples_web/examples/code_block_test.exs
git commit -m "feat: SSR'd CodeBlock component for example source"
```

---

### Task 4: The shared example page component

All the page chrome lives here once, so each example module stays ~30 lines instead of the ~80 that LiveVue's equivalent copy-pastes into every example.

**Files:**
- Create: `lib/live_react_examples_web/examples/example_components.ex`
- Test: `test/live_react_examples_web/examples/example_components_test.exs`

**Interfaces:**
- Consumes: `LiveReactExamples.Examples` (Task 1), the `examples/CodeBlock` component (Task 3).
- Produces: `LiveReactExamplesWeb.Examples.ExampleComponents.example_page/1`, taking attrs `example` (registry map, required), `tab` (string, required), `elixir_source` (string, required), `react_source` (string, required), and slots `:preview` (required), `:concepts`, `:how_it_works`.

- [ ] **Step 1: Write the failing test**

Create `test/live_react_examples_web/examples/example_components_test.exs`:

```elixir
defmodule LiveReactExamplesWeb.Examples.ExampleComponentsTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import LiveReactExamplesWeb.Examples.ExampleComponents

  alias LiveReactExamples.Examples

  # Slots are passed by rendering the component in a real ~H template rather
  # than by hand-building %{__slot__: ...} maps — those are an internal
  # representation, and a test that constructs them wrongly fails for reasons
  # that have nothing to do with the component.
  defp render_page(tab) do
    {:ok, example} = Examples.fetch("counter")
    assigns = %{example: example, tab: tab}

    rendered_to_string(~H"""
    <.example_page
      example={@example}
      tab={@tab}
      elixir_source="def mount(_, _, socket), do: {:ok, socket}"
      react_source="export function Counter() {}"
    >
      <:preview>PREVIEW HERE</:preview>
      <:concepts>CONCEPTS HERE</:concepts>
      <:how_it_works>HOW IT WORKS</:how_it_works>
    </.example_page>
    """)
  end

  test "the preview tab shows the preview and not the source" do
    html = render_page("preview")

    assert html =~ "PREVIEW HERE"
    refute html =~ "export function Counter"
  end

  test "the liveview tab shows the elixir source and not the preview" do
    html = render_page("liveview")

    assert html =~ "counter_live.ex"
    refute html =~ "PREVIEW HERE"
  end

  test "the react tab shows the react source" do
    html = render_page("react")

    assert html =~ "Counter.jsx"
    refute html =~ "PREVIEW HERE"
  end

  test "tabs are patch links so the tab is shareable and survives back" do
    html = render_page("preview")

    assert html =~ "?tab=liveview"
    assert html =~ "?tab=react"
  end

  test "the page carries its title, description and feature chips" do
    html = render_page("preview")

    assert html =~ "Counter"
    assert html =~ "Assigns become props"
    assert html =~ "phx-click"
  end

  test "the explanation slots render" do
    html = render_page("preview")

    assert html =~ "CONCEPTS HERE"
    assert html =~ "HOW IT WORKS"
  end

  test "the footer links to the next example" do
    html = render_page("preview")
    {_prev, next} = Examples.neighbours("counter")

    assert html =~ next.title
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples_web/examples/example_components_test.exs`
Expected: FAIL — the module does not exist.

- [ ] **Step 3: Write the component**

Create `lib/live_react_examples_web/examples/example_components.ex`:

```elixir
defmodule LiveReactExamplesWeb.Examples.ExampleComponents do
  @moduledoc """
  Chrome shared by every example page.

  Kept in one place deliberately: the equivalent in similar projects is
  copy-pasted into each example module, which makes adding an example an
  eighty-line ceremony and lets the pages drift apart. Here each example
  module supplies only its preview and its prose.
  """
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: LiveReactExamplesWeb.Endpoint,
    router: LiveReactExamplesWeb.Router,
    statics: LiveReactExamplesWeb.static_paths()

  import LiveReactExamplesWeb.CoreComponents, only: [icon: 1]
  import LiveReact, only: [react: 1]

  alias LiveReactExamples.Examples

  @tabs ~w(preview liveview react)

  @doc "The valid tab names; the router and LiveViews validate against this."
  def tabs, do: @tabs

  attr :example, :map, required: true
  attr :tab, :string, required: true
  attr :elixir_source, :string, required: true
  attr :react_source, :string, required: true

  slot :preview, required: true
  slot :concepts
  slot :how_it_works

  def example_page(assigns) do
    {prev, next} = Examples.neighbours(assigns.example.id)
    assigns = assign(assigns, prev: prev, next: next)

    ~H"""
    <article class="mx-auto w-full max-w-4xl">
      <header class="mb-8">
        <p class="mb-2 text-sm text-[color:var(--text-muted)]">
          {category_of(@example)}
        </p>
        <h1 class="text-3xl font-semibold text-[color:var(--text)]">{@example.title}</h1>
        <p class="mt-2 text-[color:var(--text-muted)]">{@example.description}</p>

        <ul class="mt-4 flex flex-wrap gap-2">
          <li
            :for={feature <- @example.features}
            class="rounded-full bg-brand/10 px-3 py-1 text-xs font-medium text-brand"
          >
            {feature}
          </li>
        </ul>
      </header>

      <section :if={@concepts != []} class="mb-8 rounded-lg border border-[color:var(--edge)] bg-[color:var(--surface-raised)] p-6">
        <h2 class="mb-2 text-sm font-semibold uppercase tracking-wide text-[color:var(--text-muted)]">
          Key concepts
        </h2>
        <div class="prose-sm text-[color:var(--text)]">{render_slot(@concepts)}</div>
      </section>

      <nav class="mb-4 flex gap-1 border-b border-[color:var(--edge)]" aria-label="Example view">
        <.link
          :for={{name, label} <- [{"preview", "Preview"}, {"liveview", "LiveView"}, {"react", "React"}]}
          patch={"?tab=#{name}"}
          aria-current={@tab == name && "page"}
          class={[
            "-mb-px border-b-2 px-4 py-2 text-sm font-medium",
            @tab == name && "border-brand text-brand",
            @tab != name &&
              "border-transparent text-[color:var(--text-muted)] hover:text-[color:var(--text)]"
          ]}
        >
          {label}
        </.link>
      </nav>

      <div class="mb-8">
        <div :if={@tab == "preview"} class="rounded-lg border border-[color:var(--edge)] bg-[color:var(--surface-raised)] p-6">
          {render_slot(@preview)}
        </div>

        <.react
          :if={@tab == "liveview"}
          name="examples/CodeBlock"
          code={@elixir_source}
          language="elixir"
          filename={"#{String.replace(@example.id, "-", "_")}_live.ex"}
          side="server"
        />

        <.react
          :if={@tab == "react"}
          name="examples/CodeBlock"
          code={@react_source}
          language={react_language(@example)}
          filename={"#{@example.module}.#{react_extension(@example)}"}
          side="client"
        />
      </div>

      <section :if={@how_it_works != []} class="mb-12">
        <h2 class="mb-3 text-lg font-semibold text-[color:var(--text)]">How it works</h2>
        <div class="space-y-3 text-[color:var(--text-muted)]">{render_slot(@how_it_works)}</div>
      </section>

      <footer class="flex items-center justify-between border-t border-[color:var(--edge)] pt-6 text-sm">
        <.link
          :if={@prev && @prev.status == :ready}
          navigate={~p"/examples/#{@prev.id}"}
          class="text-[color:var(--text-muted)] hover:text-[color:var(--text)]"
        >
          ← {@prev.title}
        </.link>
        <span :if={!@prev || @prev.status != :ready}></span>

        <.link
          :if={@next && @next.status == :ready}
          navigate={~p"/examples/#{@next.id}"}
          class="text-brand hover:underline"
        >
          {@next.title} →
        </.link>
        <span :if={!@next || @next.status != :ready} class="text-[color:var(--text-muted)]">
          {@next && @next.title} (coming soon)
        </span>
      </footer>
    </article>
    """
  end

  defp category_of(example) do
    Enum.find_value(Examples.by_category(), "", fn %{category: category, items: items} ->
      Enum.any?(items, &(&1.id == example.id)) && category
    end)
  end

  defp react_language(%{module: module}) do
    if File.exists?(react_path(module, "tsx")), do: "tsx", else: "jsx"
  end

  defp react_extension(example), do: react_language(example)

  defp react_path(module, ext),
    do: Path.join([File.cwd!(), "assets/react-components/examples", "#{module}.#{ext}"])
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mix test test/live_react_examples_web/examples/example_components_test.exs`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/live_react_examples_web/examples/example_components.ex \
        test/live_react_examples_web/examples/example_components_test.exs
git commit -m "feat: shared example page chrome"
```

---

### Task 5: The counter example page and its route

The first vertical slice: registry + macros + CodeBlock + chrome, wired into a real page. Proves the whole machinery before Stage 1b repeats it thirteen times.

**Files:**
- Create: `lib/live_react_examples_web/examples/counter_live.ex`
- Modify: `lib/live_react_examples_web/router.ex`
- Test: `test/live_react_examples_web/examples/counter_live_test.exs`

**Interfaces:**
- Consumes: everything from Tasks 1–4.
- Produces: the route `/examples/:slug` served by `LiveReactExamplesWeb.Examples.CounterLive` for `counter`, and the pattern every Stage 1b example module follows.

- [ ] **Step 1: Write the failing test**

Create `test/live_react_examples_web/examples/counter_live_test.exs`:

```elixir
defmodule LiveReactExamplesWeb.Examples.CounterLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the example page renders with the preview tab by default", %{conn: conn} do
    conn = get(conn, ~p"/examples/counter")
    html = html_response(conn, 200)

    assert html =~ "Counter"
    assert html =~ "Key concepts"
  end

  test "the liveview tab shows real embedded source, not an empty block", %{conn: conn} do
    html = conn |> get(~p"/examples/counter?tab=liveview") |> html_response(200)

    # The bug this whole stage exists to fix: the old implementation fetched
    # source over the network and silently rendered nothing when it 404'd.
    assert html =~ "MyAppWeb.CounterLive"
    assert html =~ "def mount"
    refute html =~ "LiveReactExamplesWeb"
  end

  test "the react tab shows the component source", %{conn: conn} do
    html = conn |> get(~p"/examples/counter?tab=react") |> html_response(200)

    assert html =~ "export function Counter"
    assert html =~ "Counter.jsx"
  end

  test "an unknown tab falls back to preview rather than erroring", %{conn: conn} do
    html = conn |> get(~p"/examples/counter?tab=nonsense") |> html_response(200)

    refute html =~ "MyAppWeb.CounterLive"
  end

  test "an unknown slug 404s", %{conn: conn} do
    assert_error_sent 404, fn -> get(conn, ~p"/examples/no-such-example") end
  end

  test "the preview is a real child liveview that responds to events", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/counter")

    preview = find_live_child(view, "counter-preview")
    assert LiveReact.Test.get_react(preview, name: "examples/Counter").props["count"] == 0

    render_hook(preview, "set_count", %{"value" => 7})
    assert LiveReact.Test.get_react(preview, name: "examples/Counter").props["count"] == 7
  end

  test "the old flat route still works — stage 1b migrates it", %{conn: conn} do
    assert {:ok, _view, _html} = live(conn, ~p"/live-counter")
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples_web/examples/counter_live_test.exs`
Expected: FAIL — no route matches `/examples/counter`.

- [ ] **Step 3: Write the example page module**

Create `lib/live_react_examples_web/examples/counter_live.ex`. This is the template Stage 1b follows for the other thirteen:

```elixir
defmodule LiveReactExamplesWeb.Examples.CounterLive do
  use LiveReactExamplesWeb, :live_view

  require LiveReactExamplesWeb.Examples.ExampleSource, as: ExampleSource

  import LiveReactExamplesWeb.Examples.ExampleComponents

  alias LiveReactExamples.Examples

  @elixir_source ExampleSource.elixir_source("Counter")
  @react_source ExampleSource.react_source("Counter")

  def mount(_params, _session, socket) do
    {:ok, example} = Examples.fetch("counter")

    {:ok,
     assign(socket,
       page_title: "#{example.title} · LiveReact examples",
       example: example,
       elixir_source: @elixir_source,
       react_source: @react_source
     )}
  end

  def handle_params(params, _uri, socket) do
    tab = if params["tab"] in tabs(), do: params["tab"], else: "preview"
    {:noreply, assign(socket, :tab, tab)}
  end

  def render(assigns) do
    ~H"""
    <.example_page
      example={@example}
      tab={@tab}
      elixir_source={@elixir_source}
      react_source={@react_source}
    >
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.CounterPreview,
          id: "counter-preview"
        )}
      </:preview>

      <:concepts>
        <p>
          Every assign that is not a reserved name is passed to React as a prop.
          <code>count</code> lives on the server; the step slider lives in React's
          <code>useState</code> and the server never sees it.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          Clicking a button calls <code>pushEvent("set_count", …)</code>, which reaches
          <code>handle_event/3</code> exactly as <code>phx-click</code> would. The server
          reassigns <code>count</code>, LiveReact diffs the props and sends only what
          changed, and React re-renders.
        </p>
        <p>
          Dragging the slider changes nothing on the server — that is the point. Local
          UI state stays local, and only what the server owns round-trips.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
```

- [ ] **Step 4: Add the route**

A LiveView route maps to a module, not to a dispatcher, so `/examples/:slug`
cannot be one route. Generate one route per ready example from the registry at
compile time. Inside the existing `scope "/", LiveReactExamplesWeb do` block
that has `pipe_through :browser`, below the current live routes, add:

```elixir
    for example <- LiveReactExamples.Examples.ready() do
      live "/examples/#{example.id}",
           Module.concat([
             LiveReactExamplesWeb.Examples,
             "#{Macro.camelize(String.replace(example.id, "-", "_"))}Live"
           ])
    end
```

Router modules are compiled once, and `Examples.ready/0` is a compile-time-known list, so this generates one route per ready example. When Stage 1b flips an example to `:ready`, its route appears automatically — but note the router will then need recompiling when the registry changes, so add the registry as an external resource at the top of the router module:

```elixir
  @external_resource Path.join([File.cwd!(), "lib/live_react_examples/examples.ex"])
```

- [ ] **Step 5: Run test to verify it passes**

Run: `mix test test/live_react_examples_web/examples/counter_live_test.exs`
Expected: PASS, 7 tests.

- [ ] **Step 6: Run the whole suite**

Run: `mix test --include assets`
Expected: PASS. Every pre-existing route test must still pass — this stage only adds.

- [ ] **Step 7: Commit**

```bash
git add lib/live_react_examples_web/examples/counter_live.ex \
        lib/live_react_examples_web/router.ex \
        test/live_react_examples_web/examples/counter_live_test.exs
git commit -m "feat: counter example page on the new system"
```

---

### Task 6: The examples index

**Files:**
- Create: `lib/live_react_examples_web/examples/index_live.ex`
- Modify: `lib/live_react_examples_web/router.ex`
- Test: `test/live_react_examples_web/examples/index_live_test.exs`

**Interfaces:**
- Consumes: `LiveReactExamples.Examples`.
- Produces: the route `/examples`.

- [ ] **Step 1: Write the failing test**

Create `test/live_react_examples_web/examples/index_live_test.exs`:

```elixir
defmodule LiveReactExamplesWeb.Examples.IndexLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias LiveReactExamples.Examples

  test "lists every example, grouped by category", %{conn: conn} do
    html = conn |> get(~p"/examples") |> html_response(200)

    for %{category: category, items: items} <- Examples.by_category() do
      assert html =~ category

      for item <- items do
        assert html =~ item.title, "#{item.title} missing from the index"
      end
    end
  end

  test "ready examples link to their page; planned ones do not", %{conn: conn} do
    html = conn |> get(~p"/examples") |> html_response(200)

    assert html =~ ~s(href="/examples/counter")
    refute html =~ ~s(href="/examples/streams")
  end

  test "explains the live/dead distinction rather than leaving it unexplained", %{conn: conn} do
    html = conn |> get(~p"/examples") |> html_response(200)

    assert html =~ "LiveView"
    assert html =~ "without"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples_web/examples/index_live_test.exs`
Expected: FAIL — no route for `/examples`.

- [ ] **Step 3: Write the index**

Create `lib/live_react_examples_web/examples/index_live.ex`:

```elixir
defmodule LiveReactExamplesWeb.Examples.IndexLive do
  use LiveReactExamplesWeb, :live_view

  alias LiveReactExamples.Examples

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Examples · LiveReact",
       categories: Examples.by_category()
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-5xl">
      <header class="mb-10">
        <h1 class="text-3xl font-semibold text-[color:var(--text)]">Examples</h1>
        <p class="mt-3 max-w-2xl text-[color:var(--text-muted)]">
          Each example shows a live preview, the LiveView that drives it, and the React
          component it renders — the real source, embedded at compile time, so what you
          read is what runs.
        </p>
        <p class="mt-3 max-w-2xl text-[color:var(--text-muted)]">
          Some examples run inside a LiveView with a socket. Others are plain
          controller-rendered pages, showing that React components work
          <strong>without</strong>
          a LiveView at all. Each example says which it is.
        </p>
      </header>

      <section :for={%{category: category, items: items} <- @categories} class="mb-10">
        <h2 class="mb-4 text-sm font-semibold uppercase tracking-wide text-[color:var(--text-muted)]">
          {category}
        </h2>

        <ul class="grid gap-4 sm:grid-cols-2">
          <li :for={item <- items}>
            <.link
              :if={item.status == :ready}
              navigate={~p"/examples/#{item.id}"}
              class="block h-full rounded-lg border border-[color:var(--edge)] bg-[color:var(--surface-raised)] p-5 hover:border-brand"
            >
              <.card_body item={item} />
            </.link>

            <div
              :if={item.status != :ready}
              class="h-full rounded-lg border border-dashed border-[color:var(--edge)] p-5 opacity-60"
            >
              <.card_body item={item} />
              <p class="mt-3 text-xs text-[color:var(--text-muted)]">coming soon</p>
            </div>
          </li>
        </ul>
      </section>
    </div>
    """
  end

  attr :item, :map, required: true

  defp card_body(assigns) do
    ~H"""
    <div class="flex items-start gap-3">
      <span class={[@item.icon, "mt-0.5 h-5 w-5 flex-none text-brand"]} />
      <div>
        <h3 class="font-medium text-[color:var(--text)]">{@item.title}</h3>
        <p class="mt-1 text-sm text-[color:var(--text-muted)]">{@item.description}</p>
        <p class="mt-2 text-xs text-[color:var(--text-muted)]">
          {if @item.kind == :live, do: "LiveView", else: "no socket"}
        </p>
      </div>
    </div>
    """
  end
end
```

- [ ] **Step 4: Add the route**

In `lib/live_react_examples_web/router.ex`, in the same browser scope, above the generated example routes:

```elixir
    live "/examples", Examples.IndexLive
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `mix test --include assets`
Expected: PASS, everything.

- [ ] **Step 6: Verify by hand what tests cannot**

```bash
mix phx.server
```

Visit `http://localhost:3200/examples` and `http://localhost:3200/examples/counter`. Check all three tabs. Confirm the LiveView and React tabs show **highlighted source, not an empty block** — that is the bug this stage exists to fix. Toggle dark mode and check the code blocks are legible. Stop the server. Record what you saw in your report; if you have no browser, say so plainly and leave this step unchecked rather than claiming it.

- [ ] **Step 7: Commit**

```bash
git add lib/live_react_examples_web/examples/index_live.ex \
        lib/live_react_examples_web/router.ex \
        test/live_react_examples_web/examples/index_live_test.exs
git commit -m "feat: examples index page"
```

---

## Done when

- `/examples` lists all 15 registry entries grouped by category.
- `/examples/counter` renders, and its LiveView and React tabs show real highlighted source embedded at compile time.
- Touching `counter_preview.ex` recompiles the page that displays it.
- All 14 pre-existing routes still work, unchanged.
- `mix test --include assets`, `mix format --check-formatted` and `mix compile --force --warnings-as-errors` all pass.

## Not in this stage

- Migrating the other 13 examples, deleting `lib/live_react_examples.ex`, `github-code.jsx`, `demo/1` and `LiveDemoAssigns`, switching the sidebar to the registry, and adding redirects from the old flat routes — Stage 1b.
- The four new examples covering 2.0 features (props diffing, file upload, `AsyncResult`, custom struct encoding) — Stage 1c.
- The landing page — Stage 2.
