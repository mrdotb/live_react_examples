# Stage 0 — Design Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put the site on a Tailwind 4 native theme with a duotone palette, working light/dark modes, a real header/footer shell, and no dead code — without changing what any page does.

**Architecture:** Theming moves out of `assets/tailwind.config.js` into `assets/css/app.css` using Tailwind 4's `@theme`, `@source`, `@plugin` and `@custom-variant`. The palette lives in `@theme`; the semantic layer that flips between themes lives in `:root` / `.dark` custom properties. Dark mode is a `.dark` class on `<html>`, set before first paint by an inline script so there is no flash. The layout shell becomes function components in a new `LiveReactExamplesWeb.SiteComponents` module so `app.html.heex` stops being a 132-line wall of markup.

**Tech Stack:** Elixir 1.20 / Phoenix LiveView, Tailwind CSS 4.3.3 via `@tailwindcss/vite`, Vite 7, LiveReact 2.0.

**Spec:** `docs/superpowers/specs/2026-09-01-site-redesign-design.md` (Stage 0 section)

## Global Constraints

- No new npm or hex dependency. Stage 0 only removes.
- Tailwind is 4.3.3 — `@theme`, `@source`, `@plugin`, `@custom-variant` are all available. Do not reintroduce a JS config or `@config`.
- Palette values, verbatim: `--color-brand: #FD4F00` (Phoenix orange, server side), `--color-client: #61DAFB` (React cyan, client side), `--color-ink: #0B1521`, `--color-paper: #FBFCFD`.
- Every page must keep rendering after every task. `mix test` and `mix format --check-formatted` pass before each commit.
- Do not touch `lib/live_react_examples.ex`, `github-code.jsx`, or the `demo/1` component. They are Stage 1's to delete, and the current layout still calls `demo/1`.
- Do not remove `simple_form`, `input`, `label` or `error` from `core_components.ex` — `hybrid_form.ex:8-9` renders them.
- Dev server runs on `localhost:3200`, Vite on `3300`.

---

### Task 1: Move Tailwind config into CSS

Deletes the legacy JS config. The heroicons plugin is the only part worth keeping; it moves to a standalone file loaded with `@plugin`.

**Files:**
- Create: `assets/heroicons.js`
- Modify: `assets/css/app.css` (whole file)
- Delete: `assets/tailwind.config.js`
- Test: `test/assets_build_test.exs`

**Interfaces:**
- Consumes: nothing.
- Produces: the Tailwind 4 token layer every later task styles against — `--color-brand`, `--color-client`, `--color-ink`, `--color-paper` as `@theme` tokens, usable as `text-brand`, `bg-client`, etc.

- [ ] **Step 1: Write the failing test**

This is a build smoke test: it compiles the real stylesheet and asserts the tokens and the heroicon masks survived the migration. It is tagged so it does not slow the default run.

Create `test/assets_build_test.exs`:

```elixir
defmodule LiveReactExamples.AssetsBuildTest do
  @moduledoc """
  Compiles the real stylesheet through Vite and asserts the Tailwind 4 CSS
  pipeline still produces our tokens. Tagged :assets because it shells out to
  npm and takes several seconds; run with `mix test --include assets`.
  """
  use ExUnit.Case, async: false

  @moduletag :assets
  @moduletag timeout: 180_000

  setup_all do
    {output, status} =
      System.cmd("npm", ["run", "build"], cd: Path.expand("../assets", __DIR__), stderr_to_stdout: true)

    assert status == 0, "asset build failed:\n#{output}"
    css = Path.expand("../priv/static/assets/app.css", __DIR__)
    assert File.exists?(css), "expected built stylesheet at #{css}"
    {:ok, css: File.read!(css)}
  end

  test "palette tokens are emitted", %{css: css} do
    assert css =~ "#FD4F00" or css =~ "#fd4f00"
    assert css =~ "#61DAFB" or css =~ "#61dafb"
  end

  test "heroicon masks are still bundled", %{css: css} do
    assert css =~ "--hero-arrow-path"
  end

  test "no legacy tailwind js config remains" do
    refute File.exists?(Path.expand("../assets/tailwind.config.js", __DIR__))
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/assets_build_test.exs --include assets`
Expected: FAIL on `no legacy tailwind js config remains` (the file still exists).

- [ ] **Step 3: Extract the heroicons plugin**

Create `assets/heroicons.js` — this is the plugin lifted verbatim out of `tailwind.config.js`, with the `require`/`module.exports` shape Tailwind 4's `@plugin` expects:

```js
const fs = require("fs");
const path = require("path");
const plugin = require("tailwindcss/plugin");

// Embeds Heroicons (https://heroicons.com) into the app.css bundle as CSS
// masks, so <.icon name="hero-x-mark-solid" /> works with no runtime request.
module.exports = plugin(function ({ matchComponents, theme }) {
  const iconsDir = path.join(__dirname, "../deps/heroicons/optimized");
  const values = {};
  const icons = [
    ["", "/24/outline"],
    ["-solid", "/24/solid"],
    ["-mini", "/20/solid"],
    ["-micro", "/16/solid"],
  ];

  icons.forEach(([suffix, dir]) => {
    fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
      const name = path.basename(file, ".svg") + suffix;
      values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
    });
  });

  matchComponents(
    {
      hero: ({ name, fullPath }) => {
        const content = fs
          .readFileSync(fullPath)
          .toString()
          .replace(/\r?\n|\r/g, "");
        let size = theme("spacing.6");
        if (name.endsWith("-mini")) size = theme("spacing.5");
        else if (name.endsWith("-micro")) size = theme("spacing.4");

        return {
          [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
          "-webkit-mask": `var(--hero-${name})`,
          mask: `var(--hero-${name})`,
          "mask-repeat": "no-repeat",
          "background-color": "currentColor",
          "vertical-align": "middle",
          display: "inline-block",
          width: size,
          height: size,
        };
      },
    },
    { values },
  );
});
```

- [ ] **Step 4: Rewrite app.css**

Replace the whole of `assets/css/app.css`:

```css
@import "tailwindcss";

/* Tailwind 4 scans these for class names (replaces `content` in the JS config) */
@source "../js";
@source "../react-components";
@source "../../lib/live_react_examples_web";

@plugin "@tailwindcss/forms";
@plugin "./heroicons.js";

/* Dark mode is an explicit class on <html>, set before first paint. */
@custom-variant dark (&:where(.dark, .dark *));

/* LiveView loading-state variants */
@custom-variant phx-click-loading (.phx-click-loading&, .phx-click-loading &);
@custom-variant phx-submit-loading (.phx-submit-loading&, .phx-submit-loading &);
@custom-variant phx-change-loading (.phx-change-loading&, .phx-change-loading &);

@theme {
  /* Duotone palette. These encode which side of the wire something is on:
     orange for the server (LiveView, handle_event), cyan for the client
     (React, local state). Used by code block headers and diagrams. */
  --color-brand: #FD4F00;
  --color-client: #61DAFB;
  --color-ink: #0B1521;
  --color-paper: #FBFCFD;

  --animate-border-beam: border-beam calc(var(--duration) * 1s) infinite linear;

  @keyframes border-beam {
    100% {
      offset-distance: 100%;
    }
  }
}
```

Note: the `--background`, `--card`, `--border` etc. custom properties that the
old `@layer base` block defined are added in Task 2. Between Task 1 and Task 2
the site will render unstyled in places; that is expected and Task 2 closes it.

- [ ] **Step 5: Delete the legacy config**

```bash
rm assets/tailwind.config.js
```

- [ ] **Step 6: Run the build test**

Run: `mix test test/assets_build_test.exs --include assets`
Expected: PASS on all three tests.

- [ ] **Step 7: Commit**

```bash
git add assets/heroicons.js assets/css/app.css test/assets_build_test.exs
git rm assets/tailwind.config.js
git commit -m "refactor: move tailwind config into app.css

Tailwind 4 reads @source/@plugin/@theme from CSS, so the legacy JS config
and @config directive go. The heroicons plugin is the only part worth
keeping and moves to assets/heroicons.js."
```

---

### Task 2: Semantic theme tokens for light and dark

The palette from Task 1 is fixed. This adds the layer that *flips*: surfaces, text and borders that differ between themes. These stay plain custom properties rather than `@theme` tokens, because `@theme` tokens are static by design.

**Files:**
- Modify: `assets/css/app.css` (append)
- Test: `test/assets_build_test.exs` (add a case)

**Interfaces:**
- Consumes: `--color-brand`, `--color-client`, `--color-ink`, `--color-paper` from Task 1.
- Produces: the semantic variables every later task and Stage 1 use — `--surface`, `--surface-raised`, `--text`, `--text-muted`, `--border`, plus the shadcn-compatible aliases (`--background`, `--foreground`, `--card`, `--card-foreground`, `--muted`, `--muted-foreground`, `--border`, `--input`, `--primary`, `--primary-foreground`, `--secondary`, `--secondary-foreground`, `--destructive`, `--destructive-foreground`, `--popover`, `--popover-foreground`, `--ring`, `--radius`) that the existing `card`/`tabs`/`button` components already reference.

- [ ] **Step 1: Write the failing test**

Add to `test/assets_build_test.exs`:

```elixir
  test "semantic tokens are defined for both themes", %{css: css} do
    assert css =~ "--surface"
    assert css =~ "--text-muted"
    # the dark variant must actually emit a rule, not just be declared
    assert css =~ ".dark"
  end

  test "shadcn aliases the existing components rely on still resolve", %{css: css} do
    for token <- ~w(--background --foreground --card --muted-foreground --border --ring --radius) do
      assert css =~ token, "missing #{token}; card/tabs/button components reference it"
    end
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/assets_build_test.exs --include assets`
Expected: FAIL — `--surface` is not defined anywhere yet.

- [ ] **Step 3: Add the semantic layer**

Append to `assets/css/app.css`:

```css
/* The semantic layer. @theme holds the fixed palette; these flip per theme,
   so they are ordinary custom properties. Components reference these, never
   the raw palette, so a theme change is a one-place edit.

   The --background/--card/--primary… aliases are kept in the HSL triple form
   the existing card, tabs and button components already consume via
   hsl(var(--x)); removing them would silently unstyle those components. */
:root {
  --surface: var(--color-paper);
  --surface-raised: #ffffff;
  --text: var(--color-ink);
  --text-muted: #5b6b7c;
  --edge: #e3e8ee;

  --background: 210 20% 99%;
  --foreground: 210 43% 9%;
  --card: 0 0% 100%;
  --card-foreground: 210 43% 9%;
  --popover: 0 0% 100%;
  --popover-foreground: 210 43% 9%;
  --primary: 18 100% 50%;
  --primary-foreground: 0 0% 100%;
  --secondary: 210 40% 96.1%;
  --secondary-foreground: 222.2 47.4% 11.2%;
  --muted: 210 40% 96.1%;
  --muted-foreground: 210 15% 42%;
  --accent: 194 95% 68%;
  --accent-foreground: 210 43% 9%;
  --destructive: 0 84.2% 60.2%;
  --destructive-foreground: 210 40% 98%;
  --border: 210 20% 91%;
  --input: 210 20% 91%;
  --ring: 18 100% 50%;
  --radius: 0.5rem;
}

.dark {
  --surface: var(--color-ink);
  --surface-raised: #111f2e;
  --text: var(--color-paper);
  --text-muted: #8ea1b4;
  --edge: #1e2f42;

  --background: 210 48% 8%;
  --foreground: 210 20% 98%;
  --card: 210 40% 12%;
  --card-foreground: 210 20% 98%;
  --popover: 210 40% 12%;
  --popover-foreground: 210 20% 98%;
  --primary: 18 100% 55%;
  --primary-foreground: 0 0% 100%;
  --secondary: 210 33% 17%;
  --secondary-foreground: 210 20% 98%;
  --muted: 210 33% 17%;
  --muted-foreground: 210 16% 65%;
  --accent: 194 95% 68%;
  --accent-foreground: 210 43% 9%;
  --destructive: 0 62.8% 45%;
  --destructive-foreground: 210 20% 98%;
  --border: 210 30% 20%;
  --input: 210 30% 20%;
  --ring: 194 95% 68%;
}

body {
  background-color: var(--surface);
  color: var(--text);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mix test test/assets_build_test.exs --include assets`
Expected: PASS.

- [ ] **Step 5: Verify both themes render by eye**

```bash
mix phx.server
```

Open `http://localhost:3200/simple`. In devtools run `document.documentElement.classList.add('dark')` and confirm the page inverts: dark ground, light text, cards still visible against the background. Then `document.documentElement.classList.remove('dark')`. Stop the server.

- [ ] **Step 6: Commit**

```bash
git add assets/css/app.css test/assets_build_test.exs
git commit -m "feat: semantic theme tokens for light and dark"
```

---

### Task 3: Dark mode toggle with no flash of wrong theme

**Files:**
- Modify: `lib/live_react_examples_web/components/layouts/root.html.heex`
- Create: `lib/live_react_examples_web/components/site_components.ex`
- Modify: `lib/live_react_examples_web.ex` (import the new module into `html_helpers`)
- Test: `test/live_react_examples_web/components/site_components_test.exs`

**Interfaces:**
- Consumes: the `.dark` class contract from Task 2.
- Produces: `LiveReactExamplesWeb.SiteComponents.theme_toggle/1` — takes no required attrs, accepts `:class`; renders a `<button id="theme-toggle">`. Task 4 places it in the header.

- [ ] **Step 1: Write the failing test**

Create `test/live_react_examples_web/components/site_components_test.exs`:

```elixir
defmodule LiveReactExamplesWeb.SiteComponentsTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import LiveReactExamplesWeb.SiteComponents

  test "theme_toggle renders a button that flips the theme" do
    html = render_component(&theme_toggle/1, %{})

    assert html =~ ~s(id="theme-toggle")
    assert html =~ "aria-label"
  end

  test "root layout sets the theme before first paint", %{conn: conn} do
    html = conn |> get(~p"/simple") |> html_response(200)

    # The inline script must run in <head>, before <body> renders, or the page
    # paints light and then snaps to dark.
    head = html |> String.split("</head>") |> hd()
    assert head =~ "localStorage"
    assert head =~ "prefers-color-scheme"
    assert head =~ "classList.add"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples_web/components/site_components_test.exs`
Expected: FAIL — `LiveReactExamplesWeb.SiteComponents` does not exist.

- [ ] **Step 3: Create the component module**

Create `lib/live_react_examples_web/components/site_components.ex`:

```elixir
defmodule LiveReactExamplesWeb.SiteComponents do
  @moduledoc """
  Chrome shared by every page: header, footer and theme toggle.

  Kept separate from `CoreComponents` (generic building blocks) because these
  are specific to this site's layout.
  """
  use Phoenix.Component

  import LiveReactExamplesWeb.CoreComponents, only: [icon: 1]

  @doc """
  Light/dark toggle.

  Writes the choice to localStorage under "theme" and flips the `.dark` class
  on `<html>`. The initial class is set by the inline script in the root
  layout, not here, so the page never paints the wrong theme first.
  """
  attr :class, :string, default: nil

  def theme_toggle(assigns) do
    ~H"""
    <button
      id="theme-toggle"
      type="button"
      aria-label="Toggle dark mode"
      class={[
        "inline-flex h-9 w-9 items-center justify-center rounded-md",
        "text-[color:var(--text-muted)] hover:text-[color:var(--text)]",
        "hover:bg-[color:var(--surface-raised)] transition-colors",
        @class
      ]}
      phx-update="ignore"
      onclick="window.__toggleTheme()"
    >
      <.icon name="hero-sun" class="h-5 w-5 dark:hidden" />
      <.icon name="hero-moon" class="hidden h-5 w-5 dark:block" />
    </button>
    """
  end
end
```

- [ ] **Step 4: Import it into the web helpers**

In `lib/live_react_examples_web.ex`, find `defp html_helpers do` and add the
import next to the existing `import LiveReactExamplesWeb.CoreComponents`:

```elixir
      import LiveReactExamplesWeb.CoreComponents
      import LiveReactExamplesWeb.SiteComponents
```

- [ ] **Step 5: Add the no-flash script to the root layout**

In `lib/live_react_examples_web/components/layouts/root.html.heex`, add this as
the **last element inside `<head>`**, after the stylesheet link. It must be a
plain blocking script, not `type="module"` — modules are deferred and would run
after first paint, which is the flash we are avoiding.

```heex
    <script>
      // Runs before <body> paints. Sets the theme class synchronously so the
      // page never renders in the wrong theme and then snaps to the right one.
      (function () {
        var stored = null;
        try { stored = localStorage.getItem("theme"); } catch (_) {}
        var dark =
          stored === "dark" ||
          (stored === null &&
            window.matchMedia("(prefers-color-scheme: dark)").matches);
        document.documentElement.classList.toggle("dark", dark);

        window.__toggleTheme = function () {
          var isDark = document.documentElement.classList.toggle("dark");
          try { localStorage.setItem("theme", isDark ? "dark" : "light"); } catch (_) {}
        };
      })();
    </script>
```

Also change the `<body>` class from `bg-background` to use the semantic token,
and the `<html>` tag to declare its colour scheme so form controls and
scrollbars follow the theme:

```heex
<html lang="en" class="[scrollbar-gutter:stable]" style="color-scheme: light dark">
```

```heex
  <body class="min-h-screen font-sans antialiased">
```

- [ ] **Step 6: Run test to verify it passes**

Run: `mix test test/live_react_examples_web/components/site_components_test.exs`
Expected: PASS.

- [ ] **Step 7: Verify no flash by eye**

```bash
mix phx.server
```

Open `http://localhost:3200/simple`, toggle to dark, then hard-reload. The page
must come up dark immediately with no white frame. Stop the server.

- [ ] **Step 8: Commit**

```bash
git add lib/live_react_examples_web/components/site_components.ex \
        lib/live_react_examples_web/components/layouts/root.html.heex \
        lib/live_react_examples_web.ex \
        test/live_react_examples_web/components/site_components_test.exs
git commit -m "feat: dark mode toggle with no flash of wrong theme"
```

---

### Task 4: Header and footer shell

`app.html.heex` is 132 lines, most of it a hand-written sidebar with the link
classes repeated 13 times. This task extracts the header and adds a footer.
**The sidebar is left alone** — Stage 1 replaces it with a registry-driven nav,
and rewriting it twice is waste.

**Files:**
- Modify: `lib/live_react_examples_web/components/site_components.ex` (add two components)
- Modify: `lib/live_react_examples_web/components/layouts/app.html.heex`
- Test: `test/live_react_examples_web/components/site_components_test.exs` (add cases)

**Interfaces:**
- Consumes: `theme_toggle/1` from Task 3.
- Produces: `site_header/1` (attrs: none required; `:class` optional) and `site_footer/1` (same). Stage 1's `example_page/1` renders inside them unchanged.

- [ ] **Step 1: Write the failing test**

Add to `test/live_react_examples_web/components/site_components_test.exs`:

```elixir
  test "site_header carries the primary nav and the toggle" do
    html = render_component(&site_header/1, %{})

    assert html =~ "/examples" or html =~ "/simple"
    assert html =~ "github.com/mrdotb/live_react"
    assert html =~ ~s(id="theme-toggle")
  end

  test "site_footer links to the library and its docs" do
    html = render_component(&site_footer/1, %{})

    assert html =~ "github.com/mrdotb/live_react"
    assert html =~ "hexdocs.pm/live_react"
  end

  test "every page renders the header and the footer", %{conn: conn} do
    html = conn |> get(~p"/simple") |> html_response(200)

    assert html =~ ~s(id="theme-toggle")
    assert html =~ "hexdocs.pm/live_react"
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples_web/components/site_components_test.exs`
Expected: FAIL — `site_header/1` is undefined.

- [ ] **Step 3: Add the two components**

Append to `lib/live_react_examples_web/components/site_components.ex`, inside
the module:

```elixir
  @github "https://github.com/mrdotb/live_react"
  @hexdocs "https://hexdocs.pm/live_react"

  @doc """
  Sticky site header: logo, primary nav, star badge and theme toggle.
  """
  attr :class, :string, default: nil

  def site_header(assigns) do
    assigns = assign(assigns, github: @github, hexdocs: @hexdocs)

    ~H"""
    <header class={[
      "sticky top-0 z-50 h-14 w-full overflow-hidden",
      "border-b border-[color:var(--edge)]",
      "bg-[color:var(--surface)]/80 backdrop-blur",
      @class
    ]}>
      <div class="mx-auto flex h-full max-w-screen-2xl items-center justify-between px-8">
        <div class="flex items-center gap-4">
          <a href="/" class="flex items-center">
            <img src={~p"/images/logo.svg"} class="w-32" alt="LiveReact" />
          </a>
          <p class="hidden rounded-full bg-brand/10 px-2 font-medium leading-6 text-brand sm:block">
            examples
          </p>
        </div>

        <nav class="flex items-center gap-2 text-sm">
          <.link
            href={~p"/simple"}
            class="rounded-md px-3 py-1.5 text-[color:var(--text-muted)] hover:text-[color:var(--text)]"
          >
            Examples
          </.link>
          <a
            href={@hexdocs}
            class="rounded-md px-3 py-1.5 text-[color:var(--text-muted)] hover:text-[color:var(--text)]"
          >
            Docs
          </a>
          <a
            href={@github}
            class="rounded-md px-3 py-1.5 text-[color:var(--text-muted)] hover:text-[color:var(--text)]"
          >
            GitHub
          </a>
          <img
            src="https://img.shields.io/github/stars/mrdotb/live_react?logo=github&logoColor=000000&label=Star&color=fafafa&style=social"
            alt="GitHub stars"
            class="ml-1 hidden md:block"
          />
          <.theme_toggle class="ml-1" />
        </nav>
      </div>
    </header>
    """
  end

  @doc """
  Site footer.
  """
  attr :class, :string, default: nil

  def site_footer(assigns) do
    assigns = assign(assigns, github: @github, hexdocs: @hexdocs)

    ~H"""
    <footer class={[
      "mt-16 border-t border-[color:var(--edge)] py-10",
      "text-sm text-[color:var(--text-muted)]",
      @class
    ]}>
      <div class="mx-auto flex max-w-screen-2xl flex-col gap-2 px-8 sm:flex-row sm:justify-between">
        <p>
          Demo application for
          <a href={@github} class="text-brand hover:underline">LiveReact</a>
          — React components inside Phoenix LiveView.
        </p>
        <div class="flex gap-4">
          <a href={@hexdocs} class="hover:text-[color:var(--text)]">Documentation</a>
          <a href={@github} class="hover:text-[color:var(--text)]">Source</a>
          <a href="https://github.com/mrdotb" class="hover:text-[color:var(--text)]">@mrdotb</a>
        </div>
      </div>
    </footer>
    """
  end
```

- [ ] **Step 4: Use them in the app layout**

In `lib/live_react_examples_web/components/layouts/app.html.heex`, replace the
entire opening `<header>…</header>` block (lines 1–21, from `<header class="overflow-hidden h-14 …"` through its closing `</header>`) with:

```heex
<.site_header />
```

Then, at the very end of the file, insert `<.site_footer />` immediately before
the `<.react :if={@demo == :flash_sonner} …>` line so the footer sits below the
main content:

```heex
<.site_footer />
<.react :if={@demo == :flash_sonner} name="FlashSonner" flash={@flash} socket={assigns[:socket]} />
<.flash_group flash={@flash} />
```

Leave the `<main>` block and the sidebar exactly as they are.

- [ ] **Step 5: Run tests to verify they pass**

Run: `mix test`
Expected: PASS, all tests including the pre-existing ones.

- [ ] **Step 6: Commit**

```bash
git add lib/live_react_examples_web/components/site_components.ex \
        lib/live_react_examples_web/components/layouts/app.html.heex \
        test/live_react_examples_web/components/site_components_test.exs
git commit -m "feat: extract site header and add a footer"
```

---

### Task 5: Delete dead core components

Six functions in `core_components.ex` have no call site anywhere in `lib/`.
Verified by grep before writing this plan: `modal`, `show_modal`, `hide_modal`,
`table`, `list`, `back`.

**Do not remove** `simple_form`, `input`, `label` or `error` — `hybrid_form.ex:8-9`
renders them. Do not remove `show`/`hide` — `flash_group/1` uses them. Do not
remove `icon` — `flash/1` and `theme_toggle/1` use it.

**Files:**
- Modify: `lib/live_react_examples_web/components/core_components.ex`
- Test: `test/live_react_examples_web/components/core_components_test.exs`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing new. This task only removes.

- [ ] **Step 1: Write the failing test**

Create `test/live_react_examples_web/components/core_components_test.exs`:

```elixir
defmodule LiveReactExamplesWeb.CoreComponentsTest do
  @moduledoc """
  Guards the boundary between components the site actually renders and the
  Phoenix generator scaffolding it never did.
  """
  use ExUnit.Case, async: true

  alias LiveReactExamplesWeb.CoreComponents

  @removed [modal: 1, show_modal: 1, show_modal: 2, hide_modal: 1, hide_modal: 2,
            table: 1, list: 1, back: 1]

  @kept [flash: 1, flash_group: 1, icon: 1, button: 1, a: 1, header: 1,
         simple_form: 1, input: 1, label: 1, error: 1,
         tabs: 1, tabs_list: 1, tabs_trigger: 1, tabs_content: 1,
         card: 1, card_content: 1, border_beam: 1,
         show: 1, show: 2, hide: 1, hide: 2]

  test "unused generator scaffolding is gone" do
    for {fun, arity} <- @removed do
      refute function_exported?(CoreComponents, fun, arity),
             "#{fun}/#{arity} is dead code and should have been removed"
    end
  end

  test "components the site renders are still exported" do
    for {fun, arity} <- @kept do
      assert function_exported?(CoreComponents, fun, arity),
             "#{fun}/#{arity} is used by the site and must not be removed"
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mix test test/live_react_examples_web/components/core_components_test.exs`
Expected: FAIL on "unused generator scaffolding is gone" — `modal/1` still exists.

- [ ] **Step 3: Remove the dead functions**

In `lib/live_react_examples_web/components/core_components.ex`, delete each of
these along with its preceding `@doc`, `attr` and `slot` declarations:

- `modal/1` — the block starting at the `@doc """\n  Renders a modal.` heredoc through the end of `def modal(assigns)`
- `table/1` — from its `@doc """\n  Renders a table` through the end of the function
- `list/1` — from its `@doc` through the end of the function
- `back/1` — from its `@doc` through the end of the function
- `show_modal/1,2` and `hide_modal/1,2` — in the `## JS Commands` section, below `show/2` and `hide/2`, which stay

Then fix `icon/1`'s docstring, which points at a file Task 1 deleted. Change:

```
  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.
```

to:

```
  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/heroicons.js`.
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `mix test`
Expected: PASS. If `mix compile` reports an unused-alias or unused-import
warning (for example `Phoenix.LiveView.JS` if nothing else used it), remove the
now-unused alias too.

- [ ] **Step 5: Verify nothing regressed**

Run: `mix compile --force --warnings-as-errors`
Expected: clean compile, no warnings.

- [ ] **Step 6: Commit**

```bash
git add lib/live_react_examples_web/components/core_components.ex \
        test/live_react_examples_web/components/core_components_test.exs
git commit -m "refactor: drop unused generator scaffolding from core components

modal, table, list, back and the modal JS helpers have no call site.
simple_form/input/label/error stay - hybrid_form renders them."
```

---

### Task 6: Drop the unused syntax-highlighter dependencies

`highlight.js` is the one that is used (`github-code.jsx`). `prism-react-renderer`
and `react-syntax-highlighter` are installed and imported nowhere.

**Files:**
- Modify: `assets/package.json`
- Modify: `assets/package-lock.json` (regenerated)
- Test: `test/assets_build_test.exs` (add a case)

**Interfaces:**
- Consumes: nothing.
- Produces: nothing. Removal only.

- [ ] **Step 1: Write the failing test**

This one does not need the compiled CSS, so put it in its own module at the
bottom of `test/assets_build_test.exs` — outside the `setup_all` — so it runs
in the default `mix test` without shelling out to npm:

```elixir
defmodule LiveReactExamples.AssetsDepsTest do
  use ExUnit.Case, async: true

  test "only one syntax highlighter is a dependency" do
    package_json =
      Path.expand("../assets/package.json", __DIR__) |> File.read!() |> Jason.decode!()

    deps = Map.get(package_json, "dependencies", %{})

    assert Map.has_key?(deps, "highlight.js"), "highlight.js is the one in use"
    refute Map.has_key?(deps, "prism-react-renderer")
    refute Map.has_key?(deps, "react-syntax-highlighter")
  end
end
```

Write it only in this module — do not also add it to `AssetsBuildTest`.

- [ ] **Step 2: Confirm they really are unused**

Run:

```bash
grep -rn "prism-react-renderer\|react-syntax-highlighter" assets/js assets/react-components
```

Expected: no output. If there *is* output, stop — the dependency is in use and
this task's premise is wrong.

- [ ] **Step 3: Run test to verify it fails**

Run: `mix test test/assets_build_test.exs --include assets`
Expected: FAIL — both packages are still in `dependencies`.

- [ ] **Step 4: Remove them**

```bash
npm --prefix assets uninstall prism-react-renderer react-syntax-highlighter
```

- [ ] **Step 5: Run test to verify it passes**

Run: `mix test test/assets_build_test.exs --include assets`
Expected: PASS. The build in `setup_all` also proves nothing broke.

- [ ] **Step 6: Commit**

```bash
git add assets/package.json assets/package-lock.json test/assets_build_test.exs
git commit -m "chore: drop unused syntax highlighter dependencies"
```

---

### Task 7: Wire the assets test into CI and close out the stage

**Files:**
- Modify: `.github/workflows/test.yml` if one exists, otherwise skip the CI edit
- Modify: `README.md`
- Test: full suite

- [ ] **Step 1: Run the assets test in CI**

`.github/workflows/tests.yml:68` runs `mix test`. The build smoke test is
tagged `:assets` and therefore excluded by default, so CI would not catch a
broken stylesheet. Change that line to:

```yaml
        run: mix test --include assets
```

The job already runs `npm install` for the asset build, so no extra setup step
is needed. If it does not, add `npm --prefix assets ci` before the test step.

- [ ] **Step 2: Document the theme layer in the README**

Add this to `README.md`, immediately before the `## Deployment` section:

```markdown
## Theming

The design tokens live in `assets/css/app.css`. Tailwind 4 reads the config
from CSS — there is no `tailwind.config.js`.

- `@theme` holds the fixed duotone palette: `--color-brand` (Phoenix orange,
  used for anything server-side) and `--color-client` (React cyan, anything
  client-side). Code block headers and diagrams are coloured by this rule.
- `:root` and `.dark` hold the semantic layer — `--surface`, `--text`,
  `--edge` and the shadcn-compatible aliases the card/tabs/button components
  consume. Components reference these, never the palette directly.

Dark mode is a `.dark` class on `<html>`, set before first paint by an inline
script in the root layout and toggled by the header control.
```

- [ ] **Step 3: Run the full suite**

Run: `mix test --include assets && mix format --check-formatted`
Expected: all pass.

- [ ] **Step 4: Verify both themes across every page**

```bash
mix phx.server
```

Walk `/simple`, `/simple-props`, `/typescript`, `/lazy`, `/live-counter`,
`/log-list`, `/flash-sonner`, `/ssr`, `/hybrid-form`, `/slot`, `/context`,
`/link-demo`, `/link-usage`, `/stream-demo` in both themes. Check specifically
that the `hybrid-form` inputs and the `flash-sonner` toasts are legible in dark
mode — those are the two places with the most borrowed styling. Stop the server.

- [ ] **Step 5: Commit**

```bash
git add README.md .github/workflows/
git commit -m "docs: document the theme layer"
```

---

## Done when

- `assets/tailwind.config.js` no longer exists and the build still emits the
  heroicon masks.
- Every page renders correctly in light and dark, with no flash on reload.
- `core_components.ex` has no function without a call site.
- `mix test --include assets` and `mix format --check-formatted` pass.
- The site is structurally unchanged — same routes, same demos, same sidebar.
  Stage 1 replaces the sidebar and the demo pages.

## Not in this stage

- The registry, `ExampleSource`, `example_page/1`, `CodeBlock` and the fix for
  the broken code tabs — Stage 1.
- Deleting `github-code.jsx` and `lib/live_react_examples.ex` — Stage 1, which
  replaces what they do.
- The landing page — Stage 2.
