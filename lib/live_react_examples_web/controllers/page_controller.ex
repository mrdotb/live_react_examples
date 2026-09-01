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
end
