defmodule LiveReactExamplesWeb.PageController do
  use LiveReactExamplesWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/examples")
  end

  # Liveness/readiness probe. Kept out of the browser pipeline so it stays cheap.
  def up(conn, _params) do
    send_resp(conn, 200, "OK")
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
    |> render(:raw_example, preview_module: module)
  end
end
