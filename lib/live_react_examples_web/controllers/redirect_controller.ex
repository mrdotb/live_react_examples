defmodule LiveReactExamplesWeb.RedirectController do
  @moduledoc """
  Permanently redirects a legacy flat URL to its new `/examples/<slug>` home.

  The old routes were the site's public URLs — the README pointed at
  `/simple` — so they redirect rather than 404, keeping existing links and
  bookmarks working.
  """
  use LiveReactExamplesWeb, :controller

  def legacy(conn, _params) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: "/examples/#{conn.private.slug}")
  end
end
