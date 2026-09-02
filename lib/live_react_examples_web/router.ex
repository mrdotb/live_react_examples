defmodule LiveReactExamplesWeb.Router do
  use LiveReactExamplesWeb, :router

  @external_resource Path.join([File.cwd!(), "lib/live_react_examples/examples.ex"])

  # The old flat URLs were public — the README pointed at /simple — so they
  # redirect permanently rather than 404. Defined as a module attribute
  # above the scope (not inside it), so the `for` comprehension below reads
  # it at compile time without depending on attribute ordering inside a
  # `scope` block.
  #
  # This is a module attribute rather than a private function: a `defp`
  # here would compile, but calling it from this top-level `for` (module
  # body code evaluated while the module is still being defined) raises
  # `undefined function` — a function body only becomes callable once its
  # enclosing module finishes compiling, and the module hasn't finished
  # compiling yet when the `scope` block below runs.
  #
  # Four of these are renamed rather than kept identical: log-list ->
  # events, flash-sonner -> server-events, slot -> slots, link-usage ->
  # link, live-counter -> counter.
  @legacy_paths %{
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

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiveReactExamplesWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # pipeline :api do
  #   plug :accepts, ["json"]
  # end

  scope "/", LiveReactExamplesWeb do
    pipe_through :browser

    get "/", PageController, :home

    for {old_path, slug} <- @legacy_paths do
      get old_path, RedirectController, :legacy,
        as: :"legacy_#{String.replace(slug, "-", "_")}",
        private: %{slug: slug}
    end

    live "/examples", Examples.IndexLive

    for example <- LiveReactExamples.Examples.ready() do
      # Derived from the registry's `module` field, not by camelizing the
      # slug: the two can diverge (e.g. slug "ssr" camelizes to "SsrLive",
      # but the registry declares module: "SSR" -> "SSRLive"), and Phoenix
      # does not verify route modules at compile time, so a mismatch here is
      # a runtime UndefinedFunctionError on request rather than a build
      # failure. See RouterTest for the compile-time guard.
      #
      # `Examples` is deliberately bare, not `LiveReactExamplesWeb.Examples`:
      # `live/2` resolves it through `Phoenix.Router.scoped_alias/2`, which
      # unconditionally prepends the enclosing scope's alias
      # (`LiveReactExamplesWeb`) and does not check whether the module is
      # already fully qualified, so a fully-qualified module here would
      # double up to `LiveReactExamplesWeb.LiveReactExamplesWeb.Examples...`.
      live "/examples/#{example.id}", Module.concat([Examples, "#{example.module}Live"])
    end

    for example <- LiveReactExamples.Examples.ready(), example.kind == :dead do
      get "/examples/#{example.id}/raw", PageController, :raw_example, as: :"raw_#{example.id}"
    end
  end

  scope "/", LiveReactExamplesWeb do
    get "/up", PageController, :up
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveReactExamplesWeb do
  #   pipe_through :api
  # end
end
