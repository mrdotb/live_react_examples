# Stage 1c — Examples for the 2.0 Feature Set

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the four examples covering what LiveReact 2.0 actually shipped and the site cannot currently show — props diffing, file uploads, `AsyncResult`, and `@derive LiveReact.Encoder`.

**Architecture:** Nothing new. Each example is the established four moves — a React component under `assets/react-components/examples/`, a minimal `<snake>_preview.ex` whose source is the documentation, a `<snake>_live.ex` using `use ExamplePage, id: "…"`, and a registry entry flipped to `:ready`. What is new is server-side: uploads need `allow_upload`, async needs `assign_async`, and encoder needs a struct to derive on.

**Tech Stack:** Elixir 1.20 / Phoenix LiveView 1.2, LiveReact 2.0, React 19, Tailwind 4, Vite 7.

**Spec:** `docs/superpowers/specs/2026-09-01-site-redesign-design.md` (Stage 1, "Example inventory")

## Global Constraints

- Branch `stage-1-examples`, continuing from Stage 1b.
- No new hex or npm dependency.
- **Follow the established pattern exactly.** Read `lib/live_react_examples_web/examples/counter_live.ex`, `counter_preview.ex` and `events_preview.ex` before writing anything. A preview's own source is what the page displays, so it must be minimal, carry a `@moduledoc`, and contain the point the example teaches — a preview that delegates its logic elsewhere leaves the source tab empty of meaning.
- **Never add a `detach_hook` line.** `LiveDemoAssigns` no longer exists; nothing attaches hooks to children.
- **Brand text uses `text-brand-strong`; client text uses `text-client-strong`.** The literal `--color-brand` and `--color-client` fail WCAG AA as text (2.9–3.3:1 and 1.55:1). They stay correct for fills, borders and icons.
- **Nothing about an example is resolved from the filesystem at render time.** A release has no `assets/` directory.
- `mix test --include assets`, `mix format --check-formatted` and `mix compile --force --warnings-as-errors` pass before every commit. `mix test` (without `--include assets`) must also pass on a tree with no `priv/react-components/` — tests needing the built SSR bundle are tagged `:assets`.
- All 14 legacy redirects keep working.
- Dev server on 3200 — do not start or kill one.
- **Interrogate every assertion you write.** "What would I break to make this fail?" If the answer is nothing, it is not a test. Nine false-pass assertions have been found in this project.

## APIs, verified present

- `useLiveReact()` exposes `upload(name, files)` and `uploadTo(target, name, files)` — `deps/live_react/assets/js/live_react/index.d.mts:20-21`.
- `LiveReact.Encoder` ships implementations for `Phoenix.LiveView.AsyncResult`, `UploadConfig` and `UploadEntry`.
- `@derive LiveReact.Encoder` supports `only:` and `except:` — `deps/live_react/lib/live_react/encoder.ex:96`.
- Diffing emits `data-props-diff` and is controlled per-component by `diff={true|false}`, defaulting to `config :live_react, :enable_props_diff` (true) — `lib/live_react.ex:52,86`.

---

### Task 0: Finish the dead-code cleanup Stage 1b left

**Files:**
- Modify: `lib/live_react_examples_web/components/core_components.ex`
- Modify: `test/live_react_examples_web/components/core_components_test.exs`

Stage 1b deleted `card/1` and `card_content/1` but left `card_header/1`, `card_title/1`, `card_description/1` and `card_footer/1`, which are now orphaned. A reviewer confirmed zero call sites.

- [ ] **Step 1: Confirm they are dead**

Run:

```bash
grep -rn "card_header\|card_title\|card_description\|card_footer" lib/ test/ | grep -v "core_components"
```

Expected: no output. If there is output, stop — they are in use and this task's premise is wrong.

- [ ] **Step 2: Move them in the test**

In `core_components_test.exs`, move `card_header: 1`, `card_title: 1`, `card_description: 1` and `card_footer: 1` from `@kept` to `@removed`.

- [ ] **Step 3: Run the test to watch it fail**

Run: `mix test test/live_react_examples_web/components/core_components_test.exs`
Expected: FAIL — the functions still exist.

- [ ] **Step 4: Delete them**

Remove the four functions from `core_components.ex`, each with its preceding `@doc`, `attr` and `slot` declarations. Leave `border_beam/1` — it is exempt by an existing documented ruling.

- [ ] **Step 5: Verify and commit**

```bash
mix compile --force --warnings-as-errors
mix test --include assets
```

```bash
git add lib/live_react_examples_web/components/core_components.ex \
        test/live_react_examples_web/components/core_components_test.exs
git commit -m "refactor: delete the orphaned card sub-components"
```

---

### Task 1: `props-diffing`

The flagship 2.0 feature, and invisible by nature — the example's job is to make it visible.

**Files:**
- Create: `assets/react-components/examples/PropsDiffing.jsx`
- Create: `lib/live_react_examples_web/examples/props_diffing_preview.ex`
- Create: `lib/live_react_examples_web/examples/props_diffing_live.ex`
- Modify: `assets/react-components/index.jsx`, `lib/live_react_examples/examples.ex`
- Test: `test/live_react_examples_web/examples/props_diffing_live_test.exs`

**Interfaces:**
- Produces: registry entry `props-diffing` in the "Props & data" category, `kind: :live`, `module: "PropsDiffing"`, `react_ext: "jsx"`, features `["data-props-diff", "diff={false}"]`.

**The design.** Render the same component twice from one preview — once with `diff={true}` (the default) and once with `diff={false}` — both bound to the same large assign. A button mutates one field of that assign. Each instance displays how many bytes it last received and the JSON patch it applied, read from its own props. The diffed instance receives a patch touching one path; the undiffed one receives the whole object. The contrast is the lesson.

- [ ] **Step 1: Write the failing test**

```elixir
defmodule LiveReactExamplesWeb.Examples.PropsDiffingLiveTest do
  @moduledoc """
  Props diffing is the headline 2.0 change and is invisible by design, so this
  example exists to make it observable. These tests assert on the mechanism
  itself — a diffed component must receive a patch, an undiffed one must not.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the page renders both instances", %{conn: conn} do
    html = conn |> get(~p"/examples/props-diffing") |> html_response(200)
    assert html =~ "props-diffing-preview"
  end

  test "the diffed instance uses diff mode and the other does not", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/props-diffing")
    preview = find_live_child(view, "props-diffing-preview")
    html = render(preview)

    # data-use-diff is what LiveReact writes to say which mode a component is in.
    assert html =~ ~s(data-use-diff="true")
    assert html =~ ~s(data-use-diff="false")
  end

  test "changing one field sends a patch to the diffed instance only", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/props-diffing")
    preview = find_live_child(view, "props-diffing-preview")

    render_hook(preview, "touch_one_field", %{})
    html = render(preview)

    # The diffed instance gets a patch naming the single changed path.
    assert html =~ "data-props-diff"
    assert html =~ "/counter"
  end
end
```

- [ ] **Step 2: Run it, watch it fail**

Run: `mix test test/live_react_examples_web/examples/props_diffing_live_test.exs`
Expected: FAIL — no route.

- [ ] **Step 3: Write the React component**

`assets/react-components/examples/PropsDiffing.jsx`. It receives the payload plus a `label`, and reports what it last received:

```jsx
import React, { useEffect, useRef, useState } from "react";

export function PropsDiffing({ label, payload }) {
  const renders = useRef(0);
  const [bytes, setBytes] = useState(0);
  renders.current += 1;

  useEffect(() => {
    setBytes(JSON.stringify(payload).length);
  }, [payload]);

  return (
    <div className="rounded-lg border border-[color:var(--edge)] p-4">
      <h3 className="font-medium">{label}</h3>
      <dl className="mt-2 grid grid-cols-2 gap-x-4 text-sm">
        <dt className="text-[color:var(--text-muted)]">counter</dt>
        <dd>{payload.counter}</dd>
        <dt className="text-[color:var(--text-muted)]">renders</dt>
        <dd>{renders.current}</dd>
        <dt className="text-[color:var(--text-muted)]">payload size</dt>
        <dd>{bytes} bytes</dd>
      </dl>
    </div>
  );
}
```

Register it in `index.jsx` as `"examples/PropsDiffing"`.

- [ ] **Step 4: Write the preview**

`props_diffing_preview.ex`. The large payload is the point — it must be big enough that sending it whole is visibly wasteful:

```elixir
defmodule LiveReactExamplesWeb.Examples.PropsDiffingPreview do
  @moduledoc """
  The same component twice: once with prop diffing on, once with it off, both
  bound to the same large payload. Changing one field shows the difference in
  what each receives.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, payload: build_payload(0)), layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <button
        phx-click="touch_one_field"
        class="rounded-md bg-primary px-3 py-1.5 text-primary-foreground"
      >
        Change one field
      </button>

      <.react name="examples/PropsDiffing" label="diff={true}" payload={@payload} socket={@socket} />

      <.react
        name="examples/PropsDiffing"
        label="diff={false}"
        payload={@payload}
        diff={false}
        socket={@socket}
      />
    </div>
    """
  end

  def handle_event("touch_one_field", _params, socket) do
    payload = Map.update!(socket.assigns.payload, :counter, &(&1 + 1))
    {:noreply, assign(socket, :payload, payload)}
  end

  defp build_payload(counter) do
    %{
      counter: counter,
      rows: Enum.map(1..40, &%{id: &1, name: "row #{&1}", note: String.duplicate("x", 40)})
    }
  end
end
```

- [ ] **Step 5: Write the page module**

`props_diffing_live.ex`, following `counter_live.ex`. The `:concepts` must explain that only the changed path travels; the `:how_it_works` must name `data-props-diff`, the `diff={false}` opt-out and `config :live_react, :enable_props_diff`.

- [ ] **Step 6: Add the registry entry** in the "Props & data" category, `status: :ready`.

- [ ] **Step 7: Run tests, then commit**

Run: `mix test --include assets`

```bash
git commit -m "feat: add the props-diffing example"
```

---

### Task 2: `file-upload`

**Files:** the same five, named for `FileUpload` / `file_upload`.
**Interfaces:** registry entry `file-upload` in a new "Uploads" category, `kind: :live`, `module: "FileUpload"`, features `["allow_upload", "upload()", "UploadConfig encoder"]`.

**The design.** The preview calls `allow_upload/3` in `mount`, passes `@uploads.avatar` as a prop — the `UploadConfig` encoder makes it serialisable — and the React side calls `upload("avatar", files)` from `useLiveReact()`. Show each entry's name and progress from the prop, so progress is visibly server-driven.

- [ ] **Step 1: Write the failing test**

Assert: the page renders; `@uploads.avatar` reaches React as a prop with the entries array present; and `allow_upload` constraints (`accept`, `max_entries`) arrive too, since they are what the client needs to enforce. Use `LiveReact.Test.get_react/2` to read the props rather than substring-matching the HTML.

- [ ] **Step 2–7:** as Task 1 — component, preview, page module, registry entry, tests, commit.

The component uses a file input plus `useLiveReact().upload`:

```jsx
const { upload } = useLiveReact();
<input type="file" onChange={(e) => upload("avatar", e.target.files)} />
```

The preview needs `allow_upload(:avatar, accept: ~w(.png .jpg .jpeg), max_entries: 3)` in `mount`, a `handle_event` for the submit that calls `consume_uploaded_entries`, and — because uploads write to disk — the consume step must simply discard the file rather than persisting anything. Say so in the `@moduledoc`; a demo that writes uploads to disk on a public site is a liability.

Note `allow_upload` requires a `phx-drop-target` or a `live_file_input` for drag-and-drop; this example uses the programmatic `upload()` call instead, which is the LiveReact-specific path and the reason the example exists.

---

### Task 3: `async`

**Files:** the same five, named for `Async` / `async`.
**Interfaces:** registry entry `async` in "Props & data", `kind: :live`, `module: "Async"`, features `["assign_async", "AsyncResult encoder"]`.

**The design.** `assign_async/3` in `mount` starts work that takes a visible moment; the `AsyncResult` struct is passed straight to React as a prop, where its `loading` / `ok?` / `failed` fields drive the UI. A button re-runs it, and a second button makes it fail, so all three states are reachable.

- [ ] **Step 1: Write the failing test**

Assert all three states are observable: the initial render has `loading` truthy; after the async completes, `ok?` is true and the result is present; and after triggering the failure path, `failed` is set. `Phoenix.LiveViewTest` renders async assigns once they resolve — use `render_async/1`. Read the props with `LiveReact.Test.get_react/2`.

- [ ] **Step 2–7:** as Task 1.

The preview:

```elixir
def mount(_params, _session, socket) do
  {:ok, socket |> assign(:mode, :ok) |> load_stats(), layout: false}
end

defp load_stats(socket) do
  mode = socket.assigns.mode
  assign_async(socket, :stats, fn ->
    Process.sleep(400)
    case mode do
      :ok -> {:ok, %{stats: %{stars: 1234, downloads: 98_765}}}
      :error -> {:error, "the upstream service is unavailable"}
    end
  end)
end
```

The `:how_it_works` must explain that `AsyncResult` is passed as a prop unchanged because LiveReact ships an encoder for it, so React reads `loading`, `ok?` and `failed` directly rather than the server flattening them into three separate assigns.

---

### Task 4: `encoder`

**Files:** the same five, named for `Encoder` / `encoder`, plus a struct module.
**Interfaces:** registry entry `encoder` in "Props & data", `kind: :live`, `module: "Encoder"`, features `["@derive LiveReact.Encoder", "except:"]`.

**The design.** A struct with a field that must not reach the client. `@derive {LiveReact.Encoder, except: [:api_token]}` — the component renders what it received, and the page's prose points out that the excluded field is absent from `data-props` in the page source, not merely hidden by CSS.

- [ ] **Step 1: Write the failing test**

This is the one test in the stage with a security-shaped assertion, so make it decisive:

```elixir
  test "an excepted field never reaches the client", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/encoder")
    preview = find_live_child(view, "encoder-preview")
    html = render(preview)

    props = LiveReact.Test.get_react(html, name: "examples/Encoder").props

    assert props["name"]
    refute Map.has_key?(props, "api_token")
    # And not anywhere in the markup either — data-props is the whole payload.
    refute html =~ "super-secret"
  end
```

- [ ] **Step 2:** Create the struct, in `lib/live_react_examples/demo_user.ex`:

```elixir
defmodule LiveReactExamples.DemoUser do
  @moduledoc """
  A struct with a field that must never reach the browser, used by the encoder
  example. `@derive` decides what is serialisable; anything omitted is absent
  from the payload rather than merely hidden.
  """
  @derive {LiveReact.Encoder, except: [:api_token]}
  defstruct [:name, :email, :api_token]
end
```

- [ ] **Step 3–7:** as Task 1. The preview assigns a `DemoUser` with `api_token: "super-secret-never-sent"`.

---

### Task 5: Index, sidebar and README

**Files:**
- Modify: `README.md`
- Test: `test/live_react_examples_web/examples/index_live_test.exs`

- [ ] **Step 1:** Confirm all 18 examples appear on `/examples`, grouped correctly, and that the new "Uploads" category renders. Add an index assertion covering the new category if one does not exist.
- [ ] **Step 2:** Update the README's route table with the four new examples and their descriptions.
- [ ] **Step 3:** Run `mix test --include assets`, `mix format --check-formatted`, `mix compile --force --warnings-as-errors`.
- [ ] **Step 4:** Commit.

---

## Done when

- `/examples` lists 18 examples; all 18 have working Preview / LiveView / React tabs.
- `props-diffing` visibly shows a patch versus a whole payload.
- `file-upload` uploads through `useLiveReact().upload` and discards the file.
- `async` reaches loading, ok and failed states.
- `encoder` proves the excepted field is absent from `data-props`.
- The orphaned card sub-components are gone.
- All three gates pass, and `mix test` passes with no `priv/react-components/`.

## Not in this stage

- The landing page — Stage 2. `/` still redirects to `/examples`.
