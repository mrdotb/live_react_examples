defmodule LiveReactExamplesWeb.RouterTest do
  @moduledoc """
  Guards two properties the router and `LiveReactExamples.Examples` must
  agree on, neither of which the compiler checks:

    * Every ready example must actually have a route. The router generates
      one literal `live "/examples/<id>"` route per ready example, so `~p`
      can't verify an interpolated `/examples/<id>` path (a dynamic
      interpolation can only match a router placeholder segment, and this
      route set has none) — this test restores that safety property by
      walking `Router.__routes__/0` directly instead.

    * The module the router derives for each ready example's route must
      actually exist. The router used to camelize the example's *slug*
      (`"ssr"` -> `SsrLive`) while the registry declares a `module` field
      (`"SSR"` -> `SSRLive`) — a real divergence Phoenix does not catch at
      compile time, since it does not verify route modules until a request
      hits them. This proves the two agree without needing a request.
  """
  use ExUnit.Case, async: true

  alias LiveReactExamples.Examples
  alias LiveReactExamplesWeb.Router

  test "/examples routes" do
    assert Enum.any?(Router.__routes__(), &(&1.path == "/examples"))
  end

  test "every ready example has a route at /examples/<id>" do
    paths = Router.__routes__() |> Enum.map(& &1.path) |> MapSet.new()

    for example <- Examples.ready() do
      assert MapSet.member?(paths, "/examples/#{example.id}"),
             "no route for ready example #{example.id} (expected /examples/#{example.id})"
    end
  end

  test "every ready example's LiveView module is the one the router derives and it exists" do
    for example <- Examples.ready() do
      module = Module.concat([LiveReactExamplesWeb.Examples, "#{example.module}Live"])

      assert Code.ensure_loaded?(module),
             "#{inspect(module)}, derived from #{example.id}'s registry module " <>
               "#{inspect(example.module)}, does not exist"
    end
  end
end
