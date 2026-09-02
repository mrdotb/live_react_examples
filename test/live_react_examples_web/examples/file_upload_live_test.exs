defmodule LiveReactExamplesWeb.Examples.FileUploadLiveTest do
  @moduledoc """
  `allow_upload/3` puts an `UploadConfig` under `@uploads.avatar`; this
  example's whole point is that it reaches React as an ordinary prop. These
  assertions read the decoded prop via `LiveReact.Test.get_react/2` rather
  than substring-matching the HTML, so a change to how the `UploadConfig`
  encoder shapes its fields (constraints going missing, or entries being
  dropped) is caught precisely, not papered over by a loose string match.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the page renders", %{conn: conn} do
    html = conn |> get(~p"/examples/file-upload") |> html_response(200)

    assert html =~ "file-upload-preview"
    assert html =~ ~s(data-name="examples/FileUpload")
  end

  test "the upload config reaches React with its constraints and its entries array", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/examples/file-upload")
    preview = find_live_child(view, "file-upload-preview")
    html = render(preview)

    react = LiveReact.Test.get_react(html, name: "examples/FileUpload")
    avatar = react.props["avatar"]

    # No files selected yet: an empty array, not a missing key or nil — the
    # client needs to be able to render zero entries without a null check.
    assert avatar["entries"] == []

    # The constraints the client needs in order to enforce the same rules
    # `allow_upload` set on the server: what to accept, and the cap.
    assert avatar["accept"] == ".png,.jpg,.jpeg"
    assert avatar["max_entries"] == 3
  end
end
