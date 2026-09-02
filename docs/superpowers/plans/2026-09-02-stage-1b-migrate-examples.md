# Stage 1b — Migrate the Remaining Examples

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move all 13 remaining examples onto the system Stage 1a built, switch the sidebar to the registry, redirect the old flat routes, and delete the machinery the old path needed — so every example's code tabs show real embedded source and there is only one way the site works.

**Architecture:** Factor before copying. Stage 1a's `counter_live.ex` is ~25 lines of ceremony around ~15 lines of prose; repeating that 13 times would duplicate `mount/3`, `handle_params/3` and the tab-fallback *logic*, not just its declaration. Task 1 extracts a `use ExamplePage, id: "…"` macro that injects all of it from the registry entry, leaving each example module carrying only its preview and its explanation. Task 2 adds the `kind: :dead` branch the spec requires but Stage 1a did not build. Only then do the migrations start.

**Tech Stack:** Elixir 1.20 / Phoenix LiveView 1.2, LiveReact 2.0, React 19, Tailwind 4, Vite 7.

**Spec:** `docs/superpowers/specs/2026-09-01-site-redesign-design.md` (Stage 1 section)

## Global Constraints

- Branch `stage-1-examples`, continuing from Stage 1a.
- No new hex or npm dependency.
- **Every route must work after every task.** Until Task 7 replaces them with redirects, the 14 legacy flat routes keep serving; `test/live_react_examples_web/routes_smoke_test.exs` covers them and must stay green until Task 7 rewrites it.
- `mix test --include assets`, `mix format --check-formatted` and `mix compile --force --warnings-as-errors` pass before every commit.
- **Brand-coloured text uses `text-brand-strong`; client-coloured text uses `text-client-strong`.** The literal `--color-brand` (#FD4F00) and `--color-client` (#61DAFB) are 2.9–3.3:1 and 1.55:1 as text on a light ground, both below the 4.5:1 AA floor. They remain correct for fills, borders and icons (icons need 3:1, not 4.5:1).
- **A preview must never re-add a `detach_hook` line.** `LiveDemoAssigns.on_mount` is guarded on `socket.parent_pid`, so it never attaches to a child LiveView. That guard is deleted along with the module in Task 7.
- **Do not resolve anything about an example from the filesystem at render time.** A release has no `assets/` directory. Everything the page needs comes from the registry.
- `assets/vite.config.js` splits SSR config by environment (React external in dev, bundled for the build). Do not touch it.
- Dev server on 3200, Vite on 3300. Do not start or kill one; a server may already be running.

---

### Task 1: The `use ExamplePage` macro

Extract the ceremony once, before it is copied 13 times.

**Files:**
- Create: `lib/live_react_examples_web/examples/example_page.ex`
- Modify: `lib/live_react_examples_web/examples/counter_live.ex`
- Test: `test/live_react_examples_web/examples/example_page_test.exs`

**Interfaces:**
- Consumes: `LiveReactExamples.Examples.fetch/1`, `ExampleSource.elixir_source/1` and `react_source/1`, `ExampleComponents.example_page/1` and `tabs/0`.
- Produces: `use LiveReactExamplesWeb.Examples.ExamplePage, id: "<slug>"`, which injects `mount/3`, `handle_params/3`, the `@example`/`@elixir_source`/`@react_source` attributes, and the imports. The using module supplies only `render/1` with its three slots.

- [ ] **Step 1: Write the failing test**

Create `test/live_react_examples_web/examples/example_page_test.exs`:

```elixir
defmodule LiveReactExamplesWeb.Examples.ExamplePageTest do
  @moduledoc """
  The tab-fallback logic lives in the macro, so it is tested once here rather
  than 14 times. A previous version of this logic was untested and silently
  rendered nothing for an unknown tab.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  test "defaults to the preview tab", %{conn: conn} do
    html = conn |> get(~p"/examples/counter") |> html_response(200)
    assert html =~ "Key concepts"
    refute html =~ "MyAppWeb.CounterLive"
  end

  test "an unknown tab falls back to preview and still renders it", %{conn: conn} do
    html = conn |> get(~p"/examples/counter?tab=nonsense") |> html_response(200)

    # The fallback must render the preview, not merely fail to render source.
    refute html =~ "MyAppWeb.CounterLive"
    assert html =~ "counter-preview"
  end

  test "each valid tab selects its own content", %{conn: conn} do
    liveview = conn |> get(~p"/examples/counter?tab=liveview") |> html_response(200)
    react = conn |> get(~p"/examples/counter?tab=react") |> html_response(200)

    assert liveview =~ "MyAppWeb.CounterLive"
    refute liveview =~ "export function Counter"

    assert react =~ "export function Counter"
    refute react =~ "MyAppWeb.CounterLive"
  end

  test "the macro sets a page title from the registry", %{conn: conn} do
    html = conn |> get(~p"/examples/counter") |> html_response(200)
    assert html =~ "Counter"
  end

  test "using the macro with an unknown slug fails at compile time" do
    assert_raise MatchError, fn ->
      Code.eval_string("""
      defmodule CompileTimeSlugCheck do
        use LiveReactExamplesWeb.Examples.ExamplePage, id: "no-such-example"
      end
      """)
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples_web/examples/example_page_test.exs`
Expected: FAIL — the module does not exist.

- [ ] **Step 3: Write the macro**

Create `lib/live_react_examples_web/examples/example_page.ex`:

```elixir
defmodule LiveReactExamplesWeb.Examples.ExamplePage do
  @moduledoc """
  Injects everything an example page needs except its content.

  Without this, each of the 14 example modules repeats the same `mount/3`,
  the same `handle_params/3` tab fallback, the same three module attributes
  and the same imports — duplicated logic, not just duplicated declarations.
  The tab fallback in particular is behaviour worth testing once rather than
  fourteen times.

  A using module supplies only `render/1`, with a `:preview` slot and its
  prose:

      defmodule MyExampleLive do
        use LiveReactExamplesWeb.Examples.ExamplePage, id: "counter"

        def render(assigns) do
          ~H\"\"\"
          <.example_page {example_assigns(assigns)}>
            <:preview>…</:preview>
            <:concepts>…</:concepts>
            <:how_it_works>…</:how_it_works>
          </.example_page>
          \"\"\"
        end
      end
  """

  defmacro __using__(opts) do
    id = Keyword.fetch!(opts, :id)

    # Resolved at compile time: an unknown slug is a build failure, not a 404.
    {:ok, example} = LiveReactExamples.Examples.fetch(id)
    name = example.module

    quote do
      use LiveReactExamplesWeb, :live_view

      require LiveReactExamplesWeb.Examples.ExampleSource, as: ExampleSource

      import LiveReactExamplesWeb.Examples.ExampleComponents

      @example unquote(Macro.escape(example))
      @elixir_source ExampleSource.elixir_source(unquote(name))
      @react_source ExampleSource.react_source(unquote(name))

      @impl Phoenix.LiveView
      def mount(_params, _session, socket) do
        {:ok,
         assign(socket,
           page_title: "#{@example.title} · LiveReact examples",
           example: @example,
           elixir_source: @elixir_source,
           react_source: @react_source
         )}
      end

      @impl Phoenix.LiveView
      def handle_params(params, _uri, socket) do
        tab = if params["tab"] in tabs(), do: params["tab"], else: "preview"
        {:noreply, assign(socket, :tab, tab)}
      end

      defoverridable mount: 3, handle_params: 3

      @doc false
      def example_assigns(assigns) do
        Map.take(assigns, [:example, :tab, :elixir_source, :react_source])
      end
    end
  end
end
```

- [ ] **Step 4: Rewrite `counter_live.ex` onto the macro**

It becomes the template every later task copies. Replace its whole body, keeping the prose:

```elixir
defmodule LiveReactExamplesWeb.Examples.CounterLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "counter"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.CounterPreview, id: "counter-preview")}
      </:preview>

      <:concepts>
        <p>
          Every assign that is not a reserved name is passed to React as a prop.
          <code>count</code> lives on the server; the step slider lives in React's
          <code>useState</code>, and the server never sees it.
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

- [ ] **Step 5: Run tests to verify they pass**

Run: `mix test --include assets`
Expected: PASS, everything. `counter_live_test.exs` from Stage 1a must still pass unchanged — the macro is a refactor, not a behaviour change.

- [ ] **Step 6: Commit**

```bash
git add lib/live_react_examples_web/examples/example_page.ex \
        lib/live_react_examples_web/examples/counter_live.ex \
        test/live_react_examples_web/examples/example_page_test.exs
git commit -m "refactor: extract the example page ceremony into a macro"
```

---

### Task 2: Dead-view examples

Four examples (`simple`, `simple-props`, `typescript`, `lazy`) exist to prove React works in a controller-rendered page with **no socket**. Rendering them as child LiveViews would destroy exactly what they demonstrate.

**Files:**
- Modify: `lib/live_react_examples_web/examples/example_components.ex`
- Create: `lib/live_react_examples_web/examples/simple_preview.ex`
- Create: `lib/live_react_examples_web/examples/simple_live.ex`
- Modify: `lib/live_react_examples_web/controllers/page_controller.ex`
- Modify: `lib/live_react_examples_web/router.ex`
- Test: `test/live_react_examples_web/examples/dead_example_test.exs`

**Interfaces:**
- Consumes: Task 1's macro, the registry's `kind` field.
- Produces: the `:dead` convention — a preview module that is a `Phoenix.Component` (not a LiveView) exposing `preview/1`, rendered inline by the page; plus a `/examples/:slug/raw` controller route serving it with no socket at all.

- [ ] **Step 1: Write the failing test**

Create `test/live_react_examples_web/examples/dead_example_test.exs`:

```elixir
defmodule LiveReactExamplesWeb.Examples.DeadExampleTest do
  @moduledoc """
  Dead-view examples demonstrate React with no LiveView socket. The page still
  needs to show them, so the preview renders inline rather than through
  live_render/3 — and a standalone route proves the socket-free claim.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  test "the example page renders the component inline", %{conn: conn} do
    html = conn |> get(~p"/examples/simple") |> html_response(200)

    assert html =~ "Hello React"
    # No child LiveView: rendering it as one would defeat the demonstration.
    refute html =~ "data-phx-session"
  end

  test "the page offers a standalone socket-free route", %{conn: conn} do
    html = conn |> get(~p"/examples/simple") |> html_response(200)
    assert html =~ "/examples/simple/raw"
  end

  test "the standalone route has no LiveView socket at all", %{conn: conn} do
    html = conn |> get(~p"/examples/simple/raw") |> html_response(200)

    assert html =~ "Hello world!"
    refute html =~ "data-phx-main"
    refute html =~ "data-phx-session"
  end

  test "the liveview tab shows the dead-view source, rewritten", %{conn: conn} do
    html = conn |> get(~p"/examples/simple?tab=liveview") |> html_response(200)

    assert html =~ "MyAppWeb"
    refute html =~ "LiveReactExamplesWeb"
  end

  test "a live example has no standalone route", %{conn: conn} do
    assert conn |> get(~p"/examples/counter") |> html_response(200) =~ "counter-preview"
    assert_raise Phoenix.Router.NoRouteError, fn -> get(conn, "/examples/counter/raw") end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples_web/examples/dead_example_test.exs`
Expected: FAIL — no `/examples/simple` route.

- [ ] **Step 3: Add the `:dead` branch to `example_page/1`**

In `example_components.ex`, the preview slot already renders whatever the caller supplies, so the component itself needs only the standalone link. Add this immediately after the preview `<div>`:

```heex
      <p :if={@example.kind == :dead} class="mt-3 text-sm text-[color:var(--text-muted)]">
        This example needs no LiveView.
        <.link
          href={"/examples/#{@example.id}/raw"}
          class="text-brand-strong hover:underline"
        >
          Open it standalone →
        </.link>
        to see it served with no socket.
      </p>
```

- [ ] **Step 4: Write the dead preview module**

Create `lib/live_react_examples_web/examples/simple_preview.ex`. It is a plain component, and its source is what the "LiveView" tab shows — so it must read as the minimal thing someone would write:

```elixir
defmodule LiveReactExamplesWeb.Examples.SimplePreview do
  @moduledoc """
  A React component rendered from an ordinary controller-rendered page. There
  is no LiveView and no socket here. This module's source is displayed on the
  example page.
  """
  use Phoenix.Component

  import LiveReact, only: [react: 1]

  def preview(assigns) do
    ~H"""
    <.react name="examples/Simple" />
    """
  end
end
```

Create `assets/react-components/examples/Simple.jsx`:

```jsx
import React from "react";

export function Simple() {
  return <div>Hello world!</div>;
}
```

Register it in `assets/react-components/index.jsx` as `"examples/Simple"`, alongside the existing `"examples/Counter"` and `"examples/CodeBlock"` entries.

- [ ] **Step 5: Write the page module**

Create `lib/live_react_examples_web/examples/simple_live.ex`:

```elixir
defmodule LiveReactExamplesWeb.Examples.SimpleLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "simple"

  alias LiveReactExamplesWeb.Examples.SimplePreview

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        <SimplePreview.preview />
      </:preview>

      <:concepts>
        <p>
          <code>react/1</code> works in any Phoenix template, not only inside a LiveView.
          This page has no socket: the component is server-rendered on the first request
          and hydrated in the browser, and there is no websocket behind it.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          The component is rendered by a plain function component from a controller
          action. Use this when you want React for its own sake — a widget, a chart, a
          third-party library — without any server-driven state.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
```

- [ ] **Step 6: Add the standalone controller route**

In `page_controller.ex`, add a single action that serves any dead example's preview with no layout chrome:

```elixir
  @doc """
  Serves a dead-view example standalone, with no LiveView anywhere on the page.
  This is the claim the example makes, so it is worth being able to see it.
  """
  def raw_example(conn, %{"slug" => slug}) do
    {:ok, example} = LiveReactExamples.Examples.fetch(slug)
    module = Module.concat([LiveReactExamplesWeb.Examples, "#{example.module}Preview"])

    conn
    |> put_layout(false)
    |> put_root_layout(html: {LiveReactExamplesWeb.Layouts, :root})
    |> render(:raw_example, preview_module: module)
  end
```

Add `lib/live_react_examples_web/controllers/page_html/raw_example.html.heex`:

```heex
<main class="p-8">
  {apply(@preview_module, :preview, [%{}])}
</main>
```

A function component called directly returns a `%Phoenix.LiveView.Rendered{}`,
which HEEx interpolates as-is — so `apply/3` is all this needs. Do not reach for
`Phoenix.LiveView.TagEngine.component/3`; it is internal API and needs caller
metadata this has no reason to synthesise.

In `router.ex`, inside the browser scope, add one route per `:dead` ready example, generated from the registry the same way the live ones are:

```elixir
    for example <- LiveReactExamples.Examples.ready(), example.kind == :dead do
      get "/examples/#{example.id}/raw", PageController, :raw_example, as: :"raw_#{example.id}"
    end
```

- [ ] **Step 7: Flip `simple` to `:ready`**

In `lib/live_react_examples/examples.ex`, change `simple`'s `status:` from `:planned` to `:ready`.

- [ ] **Step 8: Run tests to verify they pass**

Run: `mix test --include assets`
Expected: PASS. The legacy `/simple` route must still work — Task 7 replaces it.

- [ ] **Step 9: Commit**

```bash
git add lib/live_react_examples_web/examples/ lib/live_react_examples/examples.ex \
        lib/live_react_examples_web/controllers/ lib/live_react_examples_web/router.ex \
        assets/react-components/ test/live_react_examples_web/examples/dead_example_test.exs
git commit -m "feat: dead-view examples render inline with a standalone route"
```

---

### Task 3: Registry-driven sidebar

**Files:**
- Modify: `lib/live_react_examples_web/components/site_components.ex`
- Modify: `lib/live_react_examples_web/components/layouts/app.html.heex`
- Test: `test/live_react_examples_web/components/site_components_test.exs`

**Interfaces:**
- Produces: `example_nav/1` (attr `current`, the active slug or nil), rendering the registry's categories with active state and greyed `:planned` entries.

- [ ] **Step 1: Write the failing test**

Add to `site_components_test.exs`:

```elixir
  test "example_nav renders every category and marks the active example" do
    html = render_component(&example_nav/1, %{current: "counter"})

    for %{category: category, items: items} <- LiveReactExamples.Examples.by_category() do
      assert html =~ category
      for item <- items, do: assert(html =~ item.title)
    end

    assert html =~ ~s(aria-current="page")
  end

  test "example_nav links only ready examples" do
    html = render_component(&example_nav/1, %{current: nil})

    assert html =~ ~s(href="/examples/counter")
    refute html =~ ~s(href="/examples/streams")
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples_web/components/site_components_test.exs`
Expected: FAIL — `example_nav/1` undefined.

- [ ] **Step 3: Write `example_nav/1`**

Add to `site_components.ex`, replacing nothing yet:

```elixir
  @doc """
  Sidebar navigation, driven entirely by the example registry.

  The old sidebar hand-listed every route and split them into "Dead Views" and
  "LiveViews" with no explanation. Categories and the live/dead distinction now
  come from the registry, so adding an example adds its nav entry.
  """
  attr :current, :string, default: nil

  def example_nav(assigns) do
    assigns = assign(assigns, categories: LiveReactExamples.Examples.by_category())

    ~H"""
    <nav aria-label="Examples">
      <div :for={%{category: category, items: items} <- @categories} class="pb-4">
        <h4 class="mb-1 px-2 py-1 text-sm font-semibold text-[color:var(--text)]">
          {category}
        </h4>

        <div class="grid grid-flow-row auto-rows-max text-sm">
          <.link
            :for={item <- items}
            :if={item.status == :ready}
            navigate={"/examples/#{item.id}"}
            aria-current={@current == item.id && "page"}
            class={[
              "rounded-md px-2 py-1",
              @current == item.id && "font-medium text-brand-strong",
              @current != item.id &&
                "text-[color:var(--text-muted)] hover:text-[color:var(--text)]"
            ]}
          >
            {item.title}
          </.link>

          <span
            :for={item <- items}
            :if={item.status != :ready}
            class="px-2 py-1 text-[color:var(--text-muted)] opacity-50"
            title="coming soon"
          >
            {item.title}
          </span>
        </div>
      </div>
    </nav>
    """
  end
```

- [ ] **Step 4: Use it in the layout**

In `app.html.heex`, replace the entire hand-written `<nav>…</nav>` inside `<aside>` with:

```heex
          <.example_nav current={assigns[:example][:id]} />
```

Leave the `<aside>` element and its classes alone.

- [ ] **Step 5: Run tests, then commit**

Run: `mix test --include assets`
Expected: PASS — including the legacy route smoke tests, which now render the new sidebar.

```bash
git add lib/live_react_examples_web/components/ test/live_react_examples_web/components/
git commit -m "feat: registry-driven example sidebar"
```

---

### Tasks 4–6: Migrate the remaining examples

Each migration is the same four moves, established by `counter` in Task 1 and `simple` in Task 2:

1. Create `assets/react-components/examples/<Module>.{jsx,tsx}` — move the existing component, stripped of anything not essential to the point it makes. Register it in `index.jsx` under `"examples/<Module>"`.
2. Create `<snake>_preview.ex` — a LiveView (`kind: :live`) or a `Phoenix.Component` with `preview/1` (`kind: :dead`), minimal, with a `@moduledoc`. Its source is the documentation, so no page chrome.
3. Create `<snake>_live.ex` — `use ExamplePage, id: "<slug>"` plus `render/1` with `:preview`, `:concepts` and `:how_it_works`.
4. Flip the registry entry to `status: :ready`.

Then run `mix test --include assets` and commit that example.

**Do not** copy `mount/3` or `handle_params/3` into an example module — the macro provides them. **Do not** add a `detach_hook` line; the `parent_pid` guard handles it.

**Task 4 — the three remaining dead views.** Same shape as `simple` from Task 2.

| Slug | Module | Component source | The point it makes |
| --- | --- | --- | --- |
| `simple-props` | `SimpleProps` | `simple-props.jsx` | values from the template arrive as props |
| `typescript` | `Typescript` | `typescript.tsx` (`react_ext: "tsx"`) | typed props in a `.tsx` component |
| `lazy` | `Lazy` | `lazy.jsx`, `components/lazy-component.jsx` | `React.lazy` + `Suspense` inside Phoenix |

Commit as one task; they are the same shape three times.

**Task 5 — five straightforward live examples.**

| Slug | Module | From | Events | The point it makes |
| --- | --- | --- | --- | --- |
| `events` | `Events` | `log_list.ex`, `log-list.jsx` | `add_item` | `pushEvent` from React reaches `handle_event` |
| `server-events` | `ServerEvents` | `flash_sonner.ex`, `flash-sonner.jsx` | `info`, `error` | `push_event` on the server reaches `handleEvent` in React |
| `context` | `Context` | `context.ex`, `context.tsx` | `set_count` | React context alongside server props |
| `slots` | `Slots` | `slot.ex`, `slot.tsx` | `set_count` | HEEx markup passed to React as `children` |
| `ssr` | `SSR` | `ssr.ex`, `ssr.jsx` | — | `ssr={false}` for browser-only components |

Two need care:

- **`server-events`** is currently rendered from the layout (`app.html.heex` has `<.react :if={@demo == :flash_sonner} name="FlashSonner" …>`), not from its LiveView. Its preview module must render the component itself. Leave the layout line alone until Task 7 removes it.
- **`ssr`** renders the same component twice, once with `ssr={false}` and once with `ssr={true}`, and the contrast *is* the example. Keep both in the preview.

**Task 6 — the four remaining live examples.**

| Slug | Module | From | Events | The point it makes |
| --- | --- | --- | --- | --- |
| `streams` | `Streams` | `stream_demo.ex`, `stream-demo.jsx` | `add`, `edit`, `delete`, `replace_all` | `stream/4` assigns arrive as an array carrying `__dom_id` |
| `hybrid-form` | `HybridForm` | `hybrid_form.ex`, `delay-slider.tsx` | `validate`, `submit` | a LiveView form with a React control inside it |
| `link` | `Link` | `link_usage.ex`, `link.jsx` | — | the `Link` component for `href`, `patch`, `navigate` |
| `link-demo` | `LinkDemo` | `link_demo.ex`, `link-example.jsx` | — | what patch and navigate actually do to the socket |

`hybrid-form` renders `simple_form`/`input` from `CoreComponents`; those stay. `streams` is the only one using `stream/4`, so give its `:how_it_works` the `__dom_id` detail.

For each of Tasks 4, 5 and 6:

- [ ] **Step 1:** Migrate each example in the table, in order, following the four moves above.
- [ ] **Step 2:** After each one, run `mix test --include assets` and confirm green before starting the next.
- [ ] **Step 3:** Confirm the legacy flat route for that example still works — the smoke test covers it.
- [ ] **Step 4:** Commit each example separately, message `feat: migrate the <slug> example`.

---

### Task 7: Redirect the old routes and delete the old machinery

Both systems have been live at once. This ends that.

**Files:**
- Modify: `lib/live_react_examples_web/router.ex`
- Modify: `lib/live_react_examples_web/components/layouts/app.html.heex`
- Modify: `lib/live_react_examples_web/controllers/page_controller.ex`
- Modify: `lib/live_react_examples_web/components/core_components.ex`
- Delete: `lib/live_react_examples.ex`, `assets/react-components/github-code.jsx`, `lib/live_react_examples_web/live/demo_assigns.ex`, the 10 legacy LiveViews in `lib/live_react_examples_web/live/`, the 4 legacy templates in `page_html/`, the superseded components in `assets/react-components/`
- Modify: `test/live_react_examples_web/routes_smoke_test.exs`
- Test: `test/live_react_examples_web/legacy_redirect_test.exs`

- [ ] **Step 1: Write the failing test**

Create `test/live_react_examples_web/legacy_redirect_test.exs`:

```elixir
defmodule LiveReactExamplesWeb.LegacyRedirectTest do
  @moduledoc """
  The old flat routes were the site's public URLs — the README pointed at
  /simple. They redirect permanently rather than 404, so existing links and
  bookmarks keep working.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  @redirects %{
    "/simple" => "/examples/simple",
    "/simple-props" => "/examples/simple-props",
    "/typescript" => "/examples/typescript",
    "/lazy" => "/examples/lazy",
    "/live-counter" => "/examples/counter",
    "/log-list" => "/examples/events",
    "/flash-sonner" => "/examples/server-events",
    "/ssr" => "/examples/ssr",
    "/hybrid-form" => "/examples/hybrid-form",
    "/slot" => "/examples/slots",
    "/context" => "/examples/context",
    "/link-demo" => "/examples/link-demo",
    "/link-usage" => "/examples/link",
    "/stream-demo" => "/examples/streams"
  }

  test "every legacy route redirects permanently to its new home", %{conn: conn} do
    for {old, new} <- @redirects do
      conn = get(build_conn(), old)
      assert redirected_to(conn, 301) == new, "#{old} should redirect to #{new}"
    end

    _ = conn
  end

  test "every redirect target actually resolves", %{conn: conn} do
    for {_old, new} <- @redirects do
      assert conn |> get(new) |> html_response(200) =~ "Key concepts"
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples_web/legacy_redirect_test.exs`
Expected: FAIL — the legacy routes still render pages rather than redirecting.

- [ ] **Step 3: Replace the legacy routes with redirects**

In `router.ex`, delete the `live`/`get` routes for the 14 legacy paths and replace them with a single generated block:

```elixir
    # The old flat URLs were public — the README pointed at /simple — so they
    # redirect permanently rather than 404.
    # defined as a private function above the scope, not an attribute inside it
    legacy_paths = %{
      "/simple" => "simple",
      "/simple-props" => "simple-props",
      "/typescript" => "typescript",
      "/lazy" => "lazy",
      "/live-counter" => "counter",
      "/log-list" => "events",
      "/flash-sonner" => "server-events",
      "/ssr" => "ssr",
      "/hybrid-form" => "hybrid-form",
      "/slot" => "slots",
      "/context" => "context",
      "/link-demo" => "link-demo",
      "/link-usage" => "link",
      "/stream-demo" => "streams"
    }

    for {old_path, slug} <- legacy_paths() do
      get old_path, RedirectController, :legacy,
        as: :"legacy_#{String.replace(slug, "-", "_")}",
        private: %{slug: slug}
    end
```

Each route needs a distinct `as:` — several routes pointing at the same
controller action would otherwise generate colliding helper names. Define
`legacy_paths/0` as a private function above the scope rather than a module
attribute inside it, so the `for` comprehension reads it at compile time
without depending on attribute ordering inside a `scope` block.

Create `lib/live_react_examples_web/controllers/redirect_controller.ex`:

```elixir
defmodule LiveReactExamplesWeb.RedirectController do
  use LiveReactExamplesWeb, :controller

  def legacy(conn, _params) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: "/examples/#{conn.private.slug}")
  end
end
```

- [ ] **Step 4: Point `/` at the examples index**

In `page_controller.ex`, change `home/2` to redirect to `~p"/examples"` rather than `~p"/simple"`. Stage 2 replaces this with a landing page.

- [ ] **Step 5: Delete the old machinery**

```bash
git rm lib/live_react_examples.ex \
       assets/react-components/github-code.jsx \
       lib/live_react_examples_web/live/demo_assigns.ex \
       lib/live_react_examples_web/live/{counter,context,flash_sonner,hybrid_form,link_demo,link_usage,log_list,slot,ssr,stream_demo}.ex \
       lib/live_react_examples_web/controllers/page_html/{simple,simple_props,typescript,lazy}.html.heex
```

Then, in `core_components.ex`, delete `demo/1` — nothing calls it once the layout stops. In `app.html.heex`, delete the `<.demo>` wrapper and the `<.react :if={@demo == :flash_sonner} …>` line. In `page_controller.ex`, delete the `simple/2`, `simple_props/2`, `typescript/2` and `lazy/2` actions. In `index.jsx`, delete the superseded component entries and their imports, keeping only the `examples/*` ones plus anything still referenced.

- [ ] **Step 6: Rewrite the smoke test**

`routes_smoke_test.exs` currently walks the 14 legacy paths. Rewrite it to walk every `:ready` example's `/examples/<id>`, plus `/examples`, asserting each renders with the shared chrome present. Derive the list from `Examples.ready()` rather than hardcoding it, so a new example is covered automatically.

- [ ] **Step 7: Verify nothing dangles**

Run:

```bash
grep -rn "LiveReactExamples\.demo\|GithubCode\|LiveDemoAssigns\|@demo" lib/ assets/ test/
mix compile --force --warnings-as-errors
mix test --include assets
mix format --check-formatted
```

Expected: the grep returns nothing, and all three commands pass.

- [ ] **Step 8: Update the README**

Its demo URL points at `/simple`. Change it to the site root, and note the examples live under `/examples`.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "refactor: redirect legacy routes and delete the old example system"
```

---

## Done when

- All 14 examples are at `/examples/<slug>` with working Preview / LiveView / React tabs.
- The 4 dead views render inline and each offers a working `/examples/<slug>/raw`.
- Every legacy path 301-redirects to its new home.
- `lib/live_react_examples.ex`, `github-code.jsx`, `demo/1` and `LiveDemoAssigns` no longer exist.
- The sidebar is registry-driven, with active state and the live/dead distinction explained.
- `mix test --include assets`, `mix format --check-formatted` and `mix compile --force --warnings-as-errors` pass.

## Not in this stage

- The four new examples covering 2.0 features — Stage 1c.
- The landing page — Stage 2. `/` redirects to `/examples` until then.
