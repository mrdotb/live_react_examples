defmodule LiveReactExamplesWeb.Examples.FileUploadLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "file-upload"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.FileUploadPreview,
          id: "file-upload-preview"
        )}
      </:preview>

      <:concepts>
        <p>
          <code>allow_upload/3</code>
          in <code>mount/3</code>
          puts an <code>UploadConfig</code>
          under <code>@uploads.avatar</code>. Passed as a prop, LiveReact's built-in
          encoder turns it into a plain object — its constraints
          (<code>accept</code>, <code>max_entries</code>) and its current <code>entries</code>, each carrying live upload progress.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          The usual LiveView upload flow wires a <code>&lt;.live_file_input&gt;</code>
          into a <code>&lt;form phx-change phx-submit&gt;</code>, driven by
          <code>phx-drop-target</code>
          for drag-and-drop. This example instead calls <code>upload("avatar", files)</code>
          from <code>useLiveReact()</code>
          directly from a plain <code>onChange</code>
          handler —
          the LiveReact-specific path, and the reason this example exists. The
          browser starts uploading immediately; the server streams progress
          back into <code>entry.progress</code>
          on every chunk.
        </p>
        <p>
          Submitting calls <code>consume_uploaded_entries/3</code>, which reads each
          finished upload once and then removes it. This demo discards the file
          entirely rather than saving it anywhere.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
