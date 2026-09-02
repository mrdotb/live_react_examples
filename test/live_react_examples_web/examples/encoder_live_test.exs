defmodule LiveReactExamplesWeb.Examples.EncoderLiveTest do
  @moduledoc """
  `@derive {LiveReact.Encoder, except: [:api_token]}` decides what a struct
  sends to the client. This is the one test in the stage with a
  security-shaped assertion, so it must be decisive: the excepted field
  must be genuinely absent from the serialised payload, not merely hidden.
  It checks both that the props map lacks the key AND that the secret
  string appears nowhere in the rendered markup — `data-props` carries the
  whole payload, so a leak would show there even if no field named
  `api_token` were present.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the page renders", %{conn: conn} do
    html = conn |> get(~p"/examples/encoder") |> html_response(200)

    assert html =~ "encoder-preview"
    assert html =~ ~s(data-name="examples/Encoder")
  end

  test "an excepted field never reaches the client", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/encoder")
    preview = find_live_child(view, "encoder-preview")
    html = render(preview)

    props = LiveReact.Test.get_react(html, name: "examples/Encoder").props
    user = props["user"]

    # The DemoUser struct is passed as a single prop, so the derived
    # encoder's output lives under "user" rather than at the top level of
    # props — sanity-check the fields that *should* be there before
    # asserting on the one that must not be.
    assert user["name"] == "Ada Lovelace"
    refute Map.has_key?(user, "api_token")
    # And not anywhere in the markup either — data-props is the whole
    # payload, so a leak would show there even under a different key.
    refute html =~ "super-secret-never-sent"
  end
end
