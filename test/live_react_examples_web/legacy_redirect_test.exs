defmodule LiveReactExamplesWeb.LegacyRedirectTest do
  @moduledoc """
  The old flat routes were the site's public URLs — the README pointed at
  /simple. They redirect permanently rather than 404, so existing links and
  bookmarks keep working.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  @redirects %{
    "/simple" => "/examples/simple",
    "/simple-props" => "/examples/simple-props",
    "/typescript" => "/examples/typescript",
    "/lazy" => "/examples/lazy",
    "/live-counter" => "/examples/counter",
    "/log-list" => "/examples/events",
    "/flash-sonner" => "/examples/server-events",
    "/ssr" => "/examples/ssr",
    "/hybrid-form" => "/examples/hybrid-form",
    "/slot" => "/examples/slots",
    "/context" => "/examples/context",
    "/link-demo" => "/examples/link-demo",
    "/link-usage" => "/examples/link",
    "/stream-demo" => "/examples/streams"
  }

  test "every legacy route redirects permanently to its new home", %{conn: conn} do
    for {old, new} <- @redirects do
      conn = get(build_conn(), old)
      assert redirected_to(conn, 301) == new, "#{old} should redirect to #{new}"
    end

    _ = conn
  end

  test "every redirect target actually resolves", %{conn: conn} do
    for {_old, new} <- @redirects do
      assert conn |> get(new) |> html_response(200) =~ "Key concepts"
    end
  end
end
