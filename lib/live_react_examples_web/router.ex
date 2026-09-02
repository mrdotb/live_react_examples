defmodule LiveReactExamplesWeb.Router do
  use LiveReactExamplesWeb, :router

  @external_resource Path.join([File.cwd!(), "lib/live_react_examples/examples.ex"])

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
    get "/lazy", PageController, :lazy
    get "/simple", PageController, :simple
    get "/simple-props", PageController, :simple_props
    get "/typescript", PageController, :typescript

    live "/live-counter", LiveCounter
    live "/context", LiveContext
    live "/log-list", LiveLogList
    live "/flash-sonner", LiveFlashSonner
    live "/ssr", LiveSSR
    live "/hybrid-form", LiveHybridForm
    live "/slot", LiveSlot
    live "/link-demo", LiveLinkDemo
    live "/link-usage", LiveLinkUsage
    live "/stream-demo", LiveStreamDemo

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
  end

  scope "/", LiveReactExamplesWeb do
    get "/up", PageController, :up
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveReactExamplesWeb do
  #   pipe_through :api
  # end
end
