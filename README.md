# LiveReact Examples

The demo application for [LiveReact](https://github.com/mrdotb/live_react) — React
components inside Phoenix LiveView, with SSR, end-to-end reactivity and slot
interoperability.

Live demo: <https://live-react.mrdotb.com/simple>

## What's in here

A Phoenix app whose routes are each a self-contained example:

| Route | Shows |
| --- | --- |
| `/simple`, `/simple-props` | Rendering a React component from a dead view |
| `/typescript` | TypeScript components |
| `/lazy` | Lazy-loading a component |
| `/live-counter` | `pushEvent` / assigns round-trip |
| `/context` | Sharing LiveView state through React context |
| `/log-list` | Streaming updates into a component |
| `/flash-sonner` | Server events driving a client toast library |
| `/ssr` | Server-side rendering |
| `/hybrid-form` | A form split between LiveView and React |
| `/slot` | Phoenix slots as React children |
| `/link-demo`, `/link-usage` | The `Link` component for LiveView navigation |
| `/stream-demo` | Phoenix streams (insert, replace, edit, delete) |

The React components live in `assets/react-components/`, and each one is paired
with a LiveView or controller action under `lib/live_react_examples_web/`.

## Running it

Requires Elixir, Erlang and Node — versions are pinned in `mise.toml`.

```bash
mix setup      # deps.get + npm install + build client and SSR bundles
mix phx.server
```

Then visit <http://localhost:4000>.

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

## Deployment

Pushing a `v*` tag builds a Docker image and publishes it to the public
`ghcr.io/mrdotb/live-react-examples` (see `.github/workflows/publish.yml`),
tagged `vX.Y.Z`, `vX.Y` and `latest`:

```bash
git tag v0.1.0 && git push origin v0.1.0
```

The app is served at <https://live-react.mrdotb.com> from a k3s cluster, deployed
by Flux from the `ironforge-scaleway` GitOps repo under
`kubernetes/apps-stages/stage-5/default/live-react-examples`. It runs as a single
replica behind nginx-ingress with a cert-manager certificate, takes `PHX_HOST`,
`SECRET_KEY_BASE` and `PORT` from its environment, and answers the liveness and
readiness probes on `/up`.

The manifest pins the image tag, so deploying a new version means bumping `tag:`
in its `helm-release.yaml` to match the tag you just pushed.
