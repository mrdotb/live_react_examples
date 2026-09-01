defmodule LiveReactExamplesWeb.PageControllerTest do
  use LiveReactExamplesWeb.ConnCase

  test "GET / redirects to the first example", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/simple"
  end
end
