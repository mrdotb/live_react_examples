defmodule LiveReactExamplesWeb.PageControllerTest do
  use LiveReactExamplesWeb.ConnCase

  test "GET / redirects to the examples index", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/examples"
  end

  test "GET /up answers the health check", %{conn: conn} do
    conn = get(conn, ~p"/up")
    assert response(conn, 200) == "OK"
  end
end
