# LiveReact Examples — Site Redesign

**Status:** design, awaiting review
**Date:** 2026-09-01

## Problem

The site does not sell the library. Three things are wrong with it, in
descending order of damage.

**The source-code tabs are broken in production.** `GithubCode` fetches example
source at runtime from
`raw.githubusercontent.com/mrdotb/live_react/main/live_react_examples/…`. That
path stopped existing when the examples app was split into its own repo
(`e5ea646`); the URLs now 404. The fetch failure is only `console.error`'d, so
the "LiveView" and "React" tabs render an empty `<pre>`. Two of the three tabs
on every demo page show nothing.

**There is no landing page.** `/` redirects to `/simple`.
`page_html/home.html.heex` is still the stock Phoenix welcome screen — that is
where the stray fly.io link lives — and nothing routes to it. A visitor arrives
inside a demo with no explanation of what LiveReact is or why they should care.

**The 2.0 feature set is invisible.** Props diffing is the flagship change in
2.0 and has no demo. Neither do file uploads (`upload`/`uploadTo` plus the
`UploadConfig` encoder), `AsyncResult`, or `@derive LiveReact.Encoder` — the
breaking change of the release.

Underneath that, the presentation has no design system: no dark mode, a flat
sidebar split into "Dead Views 💀" and "LiveViews 🔄" with no active state and
no explanation of the distinction, Tailwind 4 driven through a legacy JS config,
three syntax highlighters installed where one is used, and ~500 lines of unused
Phoenix scaffolding in `core_components.ex`.

## Goals

1. Every example shows source that is provably the source running, with no
   network dependency.
2. A landing page that explains LiveReact to someone who has never heard of it.
3. Examples cover what 2.0 actually ships.
4. A coherent visual system, light and dark.

## Non-goals

- Documentation. The library's own docs stay in `mrdotb/live_react`; this site
  links to them.
- A CMS, blog, or search.
- Copying LiveVue examples that LiveReact has no API for. LiveReact's JS surface
  is deliberately smaller — `useLiveReact()` (`pushEvent`, `pushEventTo`,
  `handleEvent`, `removeHandleEvent`, `upload`, `uploadTo`) and `Link`. There is
  no `useLiveForm`/`useLiveUpload` equivalent to build pages around.

## Design direction

Sibling to `live_vue_website` — same structural vocabulary, own identity. The
palette is duotone and does real work: it encodes which side of the wire you are
looking at.

| Token | Value | Role |
| --- | --- | --- |
| `--color-brand` | `#FD4F00` | Phoenix orange — server, LiveView code, `handle_event` |
| `--color-client` | `#61DAFB` | React cyan — client, JSX code, local state |
| `--color-ink` | `#0B1521` | dark ground |
| `--color-paper` | `#FBFCFD` | light ground |

Every code block header, diagram box and data-flow arrow is coloured by side.
A reader learns the convention on the landing page hero and carries it through
every example.

---

## Stage 0 — Foundation

No new UI dependency. Theming moves to Tailwind 4's native CSS pipeline.

**`assets/css/app.css`** becomes the single source of theme truth:

```css
@import "tailwindcss";

@source "../js";
@source "../react-components";
@source "../../lib/live_react_examples_web";

@plugin "@tailwindcss/forms";
@plugin "./heroicons.js";

@custom-variant dark (&:where(.dark, .dark *));
@custom-variant phx-click-loading (.phx-click-loading&, .phx-click-loading &);
@custom-variant phx-submit-loading (.phx-submit-loading&, .phx-submit-loading &);
@custom-variant phx-change-loading (.phx-change-loading&, .phx-change-loading &);

@theme {
  --color-brand: #FD4F00;   /* Phoenix — server side */
  --color-client: #61DAFB;  /* React — client side */
  --color-ink: #0B1521;
  --color-paper: #FBFCFD;
}

/* Palette lives in @theme; the semantic layer flips per theme, so it is
   plain custom properties rather than @theme tokens. */
:root  { --surface: var(--color-paper); --text: var(--color-ink);   /* … */ }
.dark  { --surface: var(--color-ink);   --text: var(--color-paper); /* … */ }
```

`assets/tailwind.config.js` is deleted. The heroicons plugin — the one thing in
it worth keeping — moves to `assets/heroicons.js` and is loaded with `@plugin`.
The `content` globs become `@source`, and the three `phx-*-loading` variants
become `@custom-variant`. The `border-beam` keyframes move into `@theme`.

**Dark mode** is a `.dark` class on `<html>`, toggled by a small inline script
in `root.html.heex` that reads `localStorage` before first paint (no flash) and
falls back to `prefers-color-scheme`. A header toggle writes the preference.

**Layout shell.** `app.html.heex` splits into:

- a sticky header — logo, primary nav (Examples · Docs · GitHub), theme toggle,
  and the existing shields.io star badge (kept as an image; a live star count
  would reintroduce exactly the runtime network dependency Stage 1 removes)
- the page body
- a footer — links to the library, hex docs, the author

**Pruning.** `core_components.ex` loses `modal`, `simple_form`, `table`, `list`,
`back`, `input`, `error`, `label` — stock Phoenix scaffolding the site never
renders (~500 lines). It keeps and extends `button`, `a`, `flash`, `flash_group`,
`header`, `tabs*`, `card*`, `border_beam`. `demo/1` stays until Stage 1a
replaces it with `example_page/1` — the current layout still calls it, and
Stage 0 must leave the site working.

`prism-react-renderer` and `react-syntax-highlighter` are removed from
`package.json`; `highlight.js` is the one that is actually used and stays.

**Deliverable:** the existing site, unchanged in structure, rendering correctly
in both themes on the new token system.

---

## Stage 1 — Examples

### Registry

`lib/live_react_examples/examples.ex` is the single source of truth. Nav, index
page, prev/next links, routes and tests all derive from it.

```elixir
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
      features: ["props", "phx-click", "local state"]
    }
  ]
}
```

Public functions: `all/0` (flat list), `by_category/0` (nav and index),
`fetch/1` (slug lookup, used by the router and page), `neighbours/1` (prev/next).

`kind` is the adaptation LiveVue does not need. Four demos (`simple`,
`simple_props`, `typescript`, `lazy`) are dead views — the point of each is
React working in a controller-rendered page with **no socket**. Wrapping them in
a child LiveView would silently destroy what they demonstrate. So:

- `kind: :live` — the Preview tab renders the preview module via `live_render/3`
- `kind: :dead` — the Preview tab renders the component inline, and the page
  offers an "open standalone →" link to a genuinely socket-free controller route

This turns the unexplained "Dead Views 💀 / LiveViews 🔄" split into a
documented feature: *LiveReact works with or without a LiveView, and here is the
difference.*

### Compile-time source embedding

`ExampleSource` replaces the runtime GitHub fetch with two macros:

```elixir
@elixir_source ExampleSource.elixir_source("Counter")
@react_source  ExampleSource.react_source("Counter")
```

`elixir_source/1` reads `counter_preview.ex`, registers it as an
`@external_resource` so edits trigger recompilation, and rewrites it for
display: `LiveReactExamplesWeb.Examples.CounterPreview` → `MyAppWeb.CounterLive`,
`LiveReactExamplesWeb` → `MyAppWeb`, `name="examples/Counter"` → `name="Counter"`,
with `@moduledoc` and `layout: false` stripped. Visitors get copy-pasteable code
that cannot drift from what is running.

`react_source/1` reads `assets/react-components/examples/{Name}.{jsx,tsx}`.

This deletes `github-code.jsx` and all 170 lines of URL plumbing in
`lib/live_react_examples.ex`.

### Two modules per example

```
counter_preview.ex   minimal, self-contained; its own source is what the tab shows
counter_live.ex      the page: mount, tab handling, two content slots
```

The preview stays deliberately small — no page chrome, no explanation — because
it is documentation as much as it is a demo.

### Shared page chrome

LiveVue hand-writes the page template in all 17 of its example modules. We put
it in one component instead:

```elixir
def render(assigns) do
  ~H"""
  <.example_page example={@example} tab={@tab} sources={@sources}>
    <:concepts>
      Assigns passed to <.c>react/1</.c> arrive as props…
    </:concepts>
    <:how_it_works>
      …
    </:how_it_works>
  </.example_page>
  """
end
```

`example_page/1` owns the breadcrumb, title, feature chips, tab bar, tab
content, sidebar and prev/next footer, reading everything else from the registry
entry. Each `{Name}Live` is ~30 lines rather than ~80, and adding an example
means one registry entry plus two files.

### Tabs

Preview / LiveView / React, as today, but driven by `<.link patch={"?tab=…"}>`
so tab state is shareable and works with browser back. Invalid values fall back
to `preview`.

### Code rendering

The code block is itself a React component, SSR'd by LiveReact:

```elixir
<.react name="CodeBlock" code={@sources.elixir} language="elixir" filename="counter_live.ex" />
```

It takes source as a prop, highlights with `highlight.js`, and adds a filename
header colour-coded by side (orange for Elixir, cyan for JSX/TSX) and a copy
button. Because it renders through LiveReact's own SSR, code is present in the
initial HTML — the site dogfoods SSR on every page, and search engines see the
examples.

### Routes

```
/                      landing (Stage 2)
/examples              index grid
/examples/:slug        example page
/examples/:slug/raw    standalone dead-view route (kind: :dead only)
```

Existing flat routes (`/simple`, `/live-counter`, `/log-list`, …) become 301
redirects to their `/examples/:slug` equivalent so inbound links and the
README's demo URL keep working.

### Example inventory

14 existing examples, re-authored to the convention, plus 4 filling the 2.0 gaps.

| Category | Slug | Kind | Source | Covers |
| --- | --- | --- | --- | --- |
| Getting Started | `simple` | dead | existing | rendering a component, no socket |
| | `simple-props` | dead | existing | props from a template |
| | `counter` | live | existing | assigns → props, `phx-click` |
| Events | `events` | live | existing (`log-list`) | `pushEvent` → `handle_event` |
| | `server-events` | live | existing (`flash-sonner`) | `push_event` → `handleEvent`, toasts |
| Props & data | `props-diffing` | live | **new** | `data-props-diff`, `diff={false}` comparison |
| | `streams` | live | existing (`stream-demo`) | `stream/4` as a prop, `__dom_id` |
| | `encoder` | live | **new** | `@derive LiveReact.Encoder` on a struct |
| | `async` | live | **new** | `AsyncResult` loading/ok/failed states |
| Forms & uploads | `hybrid-form` | live | existing | LiveView form + React control |
| | `file-upload` | live | **new** | `allow_upload` + `upload()`, progress, drag-drop |
| Navigation | `link` | live | existing (`link-usage`) | `Link` href/patch/navigate |
| | `link-demo` | live | existing | patch vs navigate in practice |
| Advanced | `ssr` | live | existing | `ssr={false}` for browser-only libs |
| | `slots` | live | existing | HEEx markup as `children` |
| | `context` | live | existing | React context across components |
| | `typescript` | dead | existing | typed props |
| | `lazy` | dead | existing | `React.lazy` + `Suspense` |

The four new examples are the argument for the redesign: they are the only
places a visitor can see what 2.0 added.

**`props-diffing` deserves a note.** Diffing is invisible by nature, so the
example makes it visible: two identical components side by side, one with
`diff={false}`, each rendering a live counter of bytes received and a log of the
patches applied. Clicking "update one field of a large prop" shows the diffed
component receiving a fraction of the payload.

### Index page

`/examples` is a grid of registry-driven cards — icon, title, description,
feature chips — grouped by category, with a short foreword explaining the
Preview/LiveView/React tab convention and the live-vs-dead distinction.

---

## Stage 2 — Landing page

`page_html/home.html.heex` (the stock Phoenix screen) is deleted and `/` serves
a real landing page.

**Hero.** Headline: *React inside Phoenix LiveView, with end-to-end reactivity
and SSR.* Two CTAs: Get Started → (library README) and Examples → .

Beneath it, an animated three-layer data-flow diagram — the one idea from
`live_vue_website` most worth stealing, because it teaches the mental model in
about four seconds:

```
SERVER (LiveView)     assigns = %{count: 5}
      │ props (auto-sync)        ▲ events (pushEvent)
      ▼                          │
CLIENT (React)        props.count = 5 │ useState filter = "all"
      │ re-render
      ▼
DOM                   <p>Count: 5</p>  <button phx-click="inc">
```

It loops through two scenarios: a local state change that never leaves the
browser, and a server event that round-trips and syncs back. `framer-motion` is
already a dependency, so no new package. Server boxes and arrows are orange,
client cyan — establishing the convention the rest of the site uses. Under
`prefers-reduced-motion` it renders as a static diagram with all arrows visible.
Buttons in the DOM layer let a visitor trigger each path manually.

The hero is itself a LiveReact component, SSR'd — the landing page is a
demonstration of the thing it is selling.

**Remaining sections:** a six-item feature grid (end-to-end reactivity, built
for LiveView, SSR, incremental prop patches, TypeScript, streams); a
side-by-side JSX / LiveView code pair with the caption *props in, events out —
the server owns the state*; "when this fits / when plain LiveView is enough",
written honestly rather than as marketing; and a quick-start block with install
and a first component.

---

## Testing

Each example gets a test asserting the page renders, the tabs switch, and the
component receives the props it should, via `LiveReact.Test.get_react/2` — which
accepts both a `LiveViewTest.View` and an HTML string, so dead-view examples are
covered the same way.

Registry-driven coverage: one test iterates `Examples.all/0` and asserts every
slug routes, renders, and has both source files present. A new example cannot be
added to the registry without its page working.

Plus: `ExampleSource` transformation tests (module rename, moduledoc stripping),
theme-toggle persistence, and redirect tests for every legacy route.

## Risks

**Scope.** Three stages, ~18 examples, a new landing page. Each stage ships
independently and leaves the site working — Stage 0 alone is a visible
improvement, Stage 1 fixes the actual bug.

**Child LiveView limits.** Preview modules rendered with `live_render/3` cannot
use `handle_params/3` — only root LiveViews receive URL params. Previews needing
URL-like state use `handle_event` instead. This is a known constraint from
LiveVue's implementation notes, not a discovery waiting to happen.

**Compile-time reads and releases.** `File.read!` at compile time requires the
source files to exist during `mix compile` in the Docker build. They do — the
Dockerfile copies `lib/` and `assets/` before compiling — but the release must
not be built from a pruned tree.

**Four new examples need new server-side code** (`allow_upload`, an
`AsyncResult` fetch, a struct to derive the encoder on). These are the highest
effort items and are sequenced last within Stage 1 so the redesign is not
blocked on them.

## Sequencing

| Stage | Contents | Leaves the site |
| --- | --- | --- |
| 0 | Tailwind 4 theme, dark mode, layout shell, pruning | working, restyled |
| 1a | Registry, `ExampleSource`, `example_page`, `CodeBlock`, routes + redirects | code tabs fixed |
| 1b | Re-author the 14 existing examples to the convention | consistent |
| 1c | The 4 new 2.0 examples | complete |
| 2 | Landing page + hero animation | done |
