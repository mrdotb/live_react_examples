# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.1.0](https://github.com/mrdotb/live_react_examples/commits/v0.1.0) (2026-09-02)

### Features:

* add the encoder example ([84be8c9](https://github.com/mrdotb/live_react_examples/commit/84be8c9))
* add the async example ([f7f5c08](https://github.com/mrdotb/live_react_examples/commit/f7f5c08))
* add the file-upload example ([939e231](https://github.com/mrdotb/live_react_examples/commit/939e231))
* add the props-diffing example ([2928494](https://github.com/mrdotb/live_react_examples/commit/2928494))
* migrate the link-demo example ([5600196](https://github.com/mrdotb/live_react_examples/commit/5600196))
* migrate the link example ([b0ad0d8](https://github.com/mrdotb/live_react_examples/commit/b0ad0d8))
* migrate the hybrid-form example ([90b54d4](https://github.com/mrdotb/live_react_examples/commit/90b54d4))
* migrate the streams example ([82171ba](https://github.com/mrdotb/live_react_examples/commit/82171ba))
* migrate the ssr example ([68cc521](https://github.com/mrdotb/live_react_examples/commit/68cc521))
* migrate the slots example ([d11139b](https://github.com/mrdotb/live_react_examples/commit/d11139b))
* migrate the context example ([000a2e0](https://github.com/mrdotb/live_react_examples/commit/000a2e0))
* migrate the server-events example ([c205d27](https://github.com/mrdotb/live_react_examples/commit/c205d27))
* migrate the events example ([21e4bab](https://github.com/mrdotb/live_react_examples/commit/21e4bab))
* migrate the lazy example ([646494c](https://github.com/mrdotb/live_react_examples/commit/646494c))
* migrate the typescript example ([6d7c951](https://github.com/mrdotb/live_react_examples/commit/6d7c951))
* migrate the simple-props example ([2212025](https://github.com/mrdotb/live_react_examples/commit/2212025))
* registry-driven example sidebar ([497357c](https://github.com/mrdotb/live_react_examples/commit/497357c))
* dead-view examples render inline with a standalone route ([5d77dd7](https://github.com/mrdotb/live_react_examples/commit/5d77dd7))
* examples index page ([1d09788](https://github.com/mrdotb/live_react_examples/commit/1d09788))
* counter example page on the new system ([47e65f3](https://github.com/mrdotb/live_react_examples/commit/47e65f3))
* shared example page chrome ([bc6a026](https://github.com/mrdotb/live_react_examples/commit/bc6a026))
* SSR'd CodeBlock component for example source ([bbadbb0](https://github.com/mrdotb/live_react_examples/commit/bbadbb0))
* embed example source at compile time ([7931d52](https://github.com/mrdotb/live_react_examples/commit/7931d52))
* example registry as the single source of truth ([44ab707](https://github.com/mrdotb/live_react_examples/commit/44ab707))
* add Tidewave for MCP access to the running dev server ([b77818a](https://github.com/mrdotb/live_react_examples/commit/b77818a))
* extract site header and add a footer ([f583bf1](https://github.com/mrdotb/live_react_examples/commit/f583bf1))
* dark mode toggle with no flash of wrong theme ([d9cf8a0](https://github.com/mrdotb/live_react_examples/commit/d9cf8a0))
* semantic theme tokens for light and dark ([5beac57](https://github.com/mrdotb/live_react_examples/commit/5beac57))
* deploy to k3s instead of Fly.io ([518617b](https://github.com/mrdotb/live_react_examples/commit/518617b))
* bump otp and elixir version ([bae3bd0](https://github.com/mrdotb/live_react_examples/commit/bae3bd0))

### Bug Fixes:

* props-diffing measured size when it should measure change ([0336283](https://github.com/mrdotb/live_react_examples/commit/0336283))
* measure real props-diffing wire bytes instead of fabricating them ([af26762](https://github.com/mrdotb/live_react_examples/commit/af26762))
* stop doubling every tab title (finding 7) ([29346e4](https://github.com/mrdotb/live_react_examples/commit/29346e4))
* tag real-SSR tests :assets so a fresh clone's mix test passes (finding 6) ([4f7792d](https://github.com/mrdotb/live_react_examples/commit/4f7792d))
* give link's React tab real JSX usage of Link (finding 4) ([b241d50](https://github.com/mrdotb/live_react_examples/commit/b241d50))
* drop assets_build_test assertions on utilities finding 5 deleted ([764c86f](https://github.com/mrdotb/live_react_examples/commit/764c86f))
* three example-page defects (findings 1, 2, 3) ([90dc6a1](https://github.com/mrdotb/live_react_examples/commit/90dc6a1))
* delete core_components dead code left over from demo/1 ([11bac5e](https://github.com/mrdotb/live_react_examples/commit/11bac5e))
* give link-demo's LiveView tab the source that actually teaches it ([bf998f2](https://github.com/mrdotb/live_react_examples/commit/bf998f2))
* harden example page title test, drop redundant root layout call ([0ee2bc5](https://github.com/mrdotb/live_react_examples/commit/0ee2bc5))
* guard the handle_params hook at the source, not per-preview ([bade160](https://github.com/mrdotb/live_react_examples/commit/bade160))
* router derives example LiveView modules from the registry ([9611661](https://github.com/mrdotb/live_react_examples/commit/9611661))
* React cyan as text failed WCAG AA in light mode ([b4ab0e5](https://github.com/mrdotb/live_react_examples/commit/b4ab0e5))
* point the header Examples nav link at /examples ([c38969e](https://github.com/mrdotb/live_react_examples/commit/c38969e))
* prove SSR actually ran in CodeBlock's SSR test ([e427685](https://github.com/mrdotb/live_react_examples/commit/e427685))
* anchor strip_moduledoc's closing delimiter to its own line ([694b592](https://github.com/mrdotb/live_react_examples/commit/694b592))
* brand orange as text failed WCAG AA in light mode ([0dfe9d6](https://github.com/mrdotb/live_react_examples/commit/0dfe9d6))
* keep React external for dev SSR, bundle it only for the build ([16964cd](https://github.com/mrdotb/live_react_examples/commit/16964cd))
* bundle React into the SSR entrypoint instead of leaving bare imports ([dd77c9b](https://github.com/mrdotb/live_react_examples/commit/dd77c9b))
* address whole-branch review findings for stage 0 ([436ceb0](https://github.com/mrdotb/live_react_examples/commit/436ceb0))
* darken --primary to meet WCAG AA contrast with white text ([1510ab2](https://github.com/mrdotb/live_react_examples/commit/1510ab2))
* narrow @theme static to duotone palette, test semantic mapping ([e80939a](https://github.com/mrdotb/live_react_examples/commit/e80939a))

### Refactors:

* drop the file-upload example ([259bf47](https://github.com/mrdotb/live_react_examples/commit/259bf47))
* delete the orphaned card sub-components ([34a7110](https://github.com/mrdotb/live_react_examples/commit/34a7110))
* delete the old example system ([ab1003d](https://github.com/mrdotb/live_react_examples/commit/ab1003d))
* redirect legacy flat routes to /examples/<slug> ([7d9e1b8](https://github.com/mrdotb/live_react_examples/commit/7d9e1b8))
* extract the example page ceremony into a macro ([3db71a7](https://github.com/mrdotb/live_react_examples/commit/3db71a7))
* drop unused generator scaffolding from core components ([9adb196](https://github.com/mrdotb/live_react_examples/commit/9adb196))
* move tailwind config into app.css ([f6e0505](https://github.com/mrdotb/live_react_examples/commit/f6e0505))
