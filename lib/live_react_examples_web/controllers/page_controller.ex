defmodule LiveReactExamplesWeb.PageController do
  use LiveReactExamplesWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/simple")
  end

  # Liveness/readiness probe. Kept out of the browser pipeline so it stays cheap.
  def up(conn, _params) do
    send_resp(conn, 200, "OK")
  end

  def simple(conn, _params) do
    render(conn, :simple, demo: :simple)
  end

  def simple_props(conn, _params) do
    render(conn, :simple_props, demo: :simple_props)
  end

  def typescript(conn, _params) do
    render(conn, :typescript, demo: :typescript)
  end

  def lazy(conn, _params) do
    render(conn, :lazy, demo: :lazy)
  end

  @doc """
  Serves a dead-view example standalone, with no LiveView anywhere on the page.
  This is the claim the example makes, so it is worth being able to see it.
  """
  def raw_example(conn, _params) do
    # Not `params["slug"]`: the route is generated per example as a literal
    # path (`/examples/simple/raw`), the same way the live routes are, so it
    # has no `:slug` placeholder for the router to populate — `params` is
    # empty here. `path_info` is `["examples", slug, "raw"]` regardless.
    slug = Enum.at(conn.path_info, -2)
    {:ok, example} = LiveReactExamples.Examples.fetch(slug)
    module = Module.concat([LiveReactExamplesWeb.Examples, "#{example.module}Preview"])

    conn
    |> put_layout(false)
    |> put_root_layout(html: {LiveReactExamplesWeb.Layouts, :root})
    |> render(:raw_example, preview_module: module)
  end
end
