# LiveReact Examples

The demo application for [LiveReact](https://github.com/mrdotb/live_react) — React
components inside Phoenix LiveView, with SSR, end-to-end reactivity and slot
interoperability.

Live demo: <https://live-react.mrdotb.com>

## What's in here

A Phoenix app whose examples each live at `/examples/<slug>`:

| Route | Shows |
| --- | --- |
| `/examples/counter` | `pushEvent` / assigns round-trip |
| `/examples/simple`, `/examples/simple-props` | Rendering a React component from a dead view |
| `/examples/events` | `pushEvent` from React reaching `handle_event` on the server |
| `/examples/server-events` | Server events driving a client toast library |
| `/examples/streams` | Phoenix streams (insert, replace, edit, delete) |
| `/examples/props-diffing` | Only the changed prop path travels over the wire, unless a component opts out |
| `/examples/async` | `assign_async`'s `AsyncResult` reaches React as loading, ok and failed |
| `/examples/encoder` | `@derive LiveReact.Encoder` decides what a struct sends to the client, and what it doesn't |
| `/examples/hybrid-form` | A form split between LiveView and React |
| `/examples/link`, `/examples/link-demo` | The `Link` component for LiveView navigation |
| `/examples/ssr` | Server-side rendering |
| `/examples/slots` | Phoenix slots as React children |
| `/examples/context` | Sharing LiveView state through React context |
| `/examples/typescript` | TypeScript components |
| `/examples/lazy` | Lazy-loading a component |

Each example page offers Preview / LiveView / React tabs. The React components
live in `assets/react-components/examples/`, paired with a LiveView (or
controller action, for the dead-view examples) under
`lib/live_react_examples_web/examples/`.

## Running it

Requires Elixir, Erlang and Node — versions are pinned in `mise.toml`.

```bash
mix setup      # deps.get + npm install + build client and SSR bundles
mix phx.server
```

Then visit <http://localhost:3200>.

## Developing against a local LiveReact checkout

By default the app depends on the published Hex package, which is what the
Docker build uses. To point it at a local clone of the library instead, set
`LIVE_REACT_PATH`:

```bash
git clone https://github.com/mrdotb/live_react.git
git clone https://github.com/mrdotb/live_react_examples.git
cd live_react_examples

export LIVE_REACT_PATH=../live_react
mix deps.get

# The JS side resolves the library through `file:../deps/live_react`
# (see assets/package.json), and Mix does not populate deps/ for a path
# dependency, so point it at the checkout yourself:
ln -sfn ../../live_react deps/live_react

mix setup
mix phx.server
```

Two things to know about this mode:

- Keep `LIVE_REACT_PATH` exported for every `mix` command in that shell.
  Dropping it switches the app back to the Hex release on the next
  `mix deps.get`, and re-fetching over the symlink replaces it.
- The local library pulls in dependencies the released package doesn't have, so
  `mix deps.get` will add entries to `mix.lock`. Don't commit those.

## Theming

The design tokens live in `assets/css/app.css`. Tailwind 4 reads the config
from CSS — there is no `tailwind.config.js`.

- `@theme static` holds the fixed duotone palette: `--color-brand` (Phoenix
  orange) and `--color-client` (React cyan). Code block headers and diagrams
  are coloured by this rule. `static` forces Tailwind to keep emitting it
  even though not every value has a call site yet.
- a plain `@theme` (no `static`) maps `--color-primary`, `--color-card`,
  `--color-ring` and their siblings to the `hsl(var(--x))` custom properties
  below — it's what regenerates the `bg-card` / `text-card-foreground` /
  `ring-ring` utilities the old `tailwind.config.js` used to produce, so
  deleting it unstyles the whole site. Left off `static` so unused aliases
  still tree-shake.
- `:root` and `.dark` hold the values that actually flip per theme —
  `--surface`, `--text`, `--edge` and the shadcn-compatible HSL aliases
  (`--background`, `--card`, `--primary`, …) the card/tabs/button components
  consume. `--primary`, the interactive fill, is deliberately darker than
  `--color-brand` so white text on it clears the 4.5:1 WCAG AA contrast
  minimum. Components reference these, never the palette directly.

Dark mode is a `.dark` class on `<html>`, set before first paint by an inline
script in the root layout and toggled by the header control.

## Deployment

Pushing a `v*` tag builds a Docker image and publishes it to the public
`ghcr.io/mrdotb/live-react-examples` (see `.github/workflows/publish.yml`),
tagged `vX.Y.Z`, `vX.Y` and `latest`:

Releases are cut with [git_ops](https://github.com/zachdaniel/git_ops), which
derives the next version from Conventional Commit messages, rewrites
`CHANGELOG.md` and creates the tag:

```bash
mix git_ops.release        # --dry-run first to see what it would do
git push && git push --tags
```

`feat:` bumps the minor version, `fix:` the patch; a `!` or a
`BREAKING CHANGE:` footer bumps the major. Commits typed `chore`, `docs`,
`test` and `ci` are kept out of the changelog. If nothing since the last tag
warrants a release, git_ops says so rather than tagging.

The app is served at <https://live-react.mrdotb.com> from a k3s cluster, deployed
by Flux from the `ironforge-scaleway` GitOps repo under
`kubernetes/apps-stages/stage-5/default/live-react-examples`. It runs as a single
replica behind nginx-ingress with a cert-manager certificate, takes `PHX_HOST`,
`SECRET_KEY_BASE` and `PORT` from its environment, and answers the liveness and
readiness probes on `/up`.

The manifest pins the image tag, so deploying a new version means bumping `tag:`
in its `helm-release.yaml` to match the tag you just pushed.
