defmodule LiveReactExamplesWeb.Examples.SSRLiveTest do
  @moduledoc """
  `ssr={true}` on this page overrides `config :live_react, ssr: false`
  (config/test.exs), so the second test below exercises real NodeJS SSR via
  `priv/react-components/server.js`. That directory is gitignored and
  populated only by `mix assets.build` / the asset build pipeline (see
  config/test.exs's comment on `config :live_react, ssr: false`) — on a
  fresh clone before that has run, `NodeJS.Supervisor.call!/3` raises an
  unreadable `NodeJS.Error` instead of a normal test failure. Tagged
  `:assets` for the same reason `assets_build_test.exs` is: excluded from
  the default `mix test` run, included with `mix test --include assets`.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  @moduletag :assets

  test "the example page renders with the preview tab by default", %{conn: conn} do
    conn = get(conn, ~p"/examples/ssr")
    html = html_response(conn, 200)

    assert html =~ "SSR Control"
    assert html =~ ~s(data-name="examples/SSR")
  end

  test "ssr={true} actually renders the component's HTML on the first response, ssr={false} does not",
       %{conn: conn} do
    html = conn |> get(~p"/examples/ssr") |> html_response(200)

    # The whole point of this example is the contrast; assert on the actual
    # server-rendered markup, not just that both instances mounted. Both
    # instances share the component name, so split on their distinct ids
    # (LiveReact numbers them "examples/SSR-1", "examples/SSR-2", …) rather
    # than trying to tell them apart by content, which is what's under test.
    [_before, ssr_true_onward] = String.split(html, ~s(id="examples/SSR-1"), parts: 2)

    [ssr_true, ssr_false_onward] =
      String.split(ssr_true_onward, ~s(id="examples/SSR-2"), parts: 2)

    ssr_false = String.slice(ssr_false_onward, 0, 300)

    assert ssr_true =~ "data-ssr"
    # `data-props` always carries the text (needed to hydrate either way);
    # what proves ssr={true} actually rendered is the *child* markup the
    # component itself produces, present here and absent below.
    assert ssr_true =~ ~s(<div class="rounded-md border px-4 py-2">Rendered on the server</div>)

    refute ssr_false =~ "data-ssr"
    refute ssr_false =~ ~s(<div class="rounded-md border px-4 py-2">)
  end
end
