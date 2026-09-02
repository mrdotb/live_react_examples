defmodule LiveReactExamplesWeb.Examples.ExampleComponents do
  @moduledoc """
  Chrome shared by every example page.

  Kept in one place deliberately: the equivalent in similar projects is
  copy-pasted into each example module, which makes adding an example an
  eighty-line ceremony and lets the pages drift apart. Here each example
  module supplies only its preview and its prose.
  """
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: LiveReactExamplesWeb.Endpoint,
    router: LiveReactExamplesWeb.Router,
    statics: LiveReactExamplesWeb.static_paths()

  import LiveReact, only: [react: 1]

  alias LiveReactExamples.Examples

  @tabs ~w(preview liveview react)

  @doc "The valid tab names; the router and LiveViews validate against this."
  def tabs, do: @tabs

  attr :example, :map, required: true
  attr :tab, :string, required: true
  attr :elixir_source, :string, required: true
  attr :react_source, :string, required: true

  slot :preview, required: true
  slot :concepts
  slot :how_it_works

  def example_page(assigns) do
    {prev, next} = Examples.neighbours(assigns.example.id)
    assigns = assign(assigns, prev: prev, next: next)

    ~H"""
    <article class="mx-auto w-full max-w-4xl">
      <header class="mb-8">
        <p class="mb-2 text-sm text-[color:var(--text-muted)]">
          {category_of(@example)}
        </p>
        <h1 class="text-3xl font-semibold text-[color:var(--text)]">{@example.title}</h1>
        <p class="mt-2 text-[color:var(--text-muted)]">{@example.description}</p>

        <ul class="mt-4 flex flex-wrap gap-2">
          <li
            :for={feature <- @example.features}
            class="rounded-full bg-brand/10 px-3 py-1 text-xs font-medium text-brand-strong"
          >
            {feature}
          </li>
        </ul>
      </header>

      <section
        :if={@concepts != []}
        class="mb-8 rounded-lg border border-[color:var(--edge)] bg-[color:var(--surface-raised)] p-6"
      >
        <h2 class="mb-2 text-sm font-semibold uppercase tracking-wide text-[color:var(--text-muted)]">
          Key concepts
        </h2>
        <div class="prose-sm text-[color:var(--text)]">{render_slot(@concepts)}</div>
      </section>

      <nav class="mb-4 flex gap-1 border-b border-[color:var(--edge)]" aria-label="Example view">
        <.link
          :for={
            {name, label} <- [{"preview", "Preview"}, {"liveview", "LiveView"}, {"react", "React"}]
          }
          patch={"?tab=#{name}"}
          aria-current={@tab == name && "page"}
          class={[
            "-mb-px border-b-2 px-4 py-2 text-sm font-medium",
            @tab == name && "border-brand text-brand-strong",
            @tab != name &&
              "border-transparent text-[color:var(--text-muted)] hover:text-[color:var(--text)]"
          ]}
        >
          {label}
        </.link>
      </nav>

      <div class="mb-8">
        <div
          :if={@tab == "preview"}
          class="rounded-lg border border-[color:var(--edge)] bg-[color:var(--surface-raised)] p-6"
        >
          {render_slot(@preview)}
        </div>

        <p :if={@example.kind == :dead} class="mt-3 text-sm text-[color:var(--text-muted)]">
          This example needs no LiveView.
          <.link
            href={"/examples/#{@example.id}/raw"}
            class="text-brand-strong hover:underline"
          >
            Open it standalone →
          </.link>
          to see it served with no socket.
        </p>

        <.react
          :if={@tab == "liveview"}
          name="examples/CodeBlock"
          code={@elixir_source}
          language="elixir"
          filename={"#{String.replace(@example.id, "-", "_")}_live.ex"}
          side="server"
        />

        <.react
          :if={@tab == "react"}
          name="examples/CodeBlock"
          code={@react_source}
          language={@example.react_ext}
          filename={"#{@example.module}.#{@example.react_ext}"}
          side="client"
        />
      </div>

      <section :if={@how_it_works != []} class="mb-12">
        <h2 class="mb-3 text-lg font-semibold text-[color:var(--text)]">How it works</h2>
        <div class="space-y-3 text-[color:var(--text-muted)]">{render_slot(@how_it_works)}</div>
      </section>

      <footer class="flex items-center justify-between border-t border-[color:var(--edge)] pt-6 text-sm">
        <%!--
          Not `~p"/examples/#{...}"`: the router generates one literal route
          per ready example (`/examples/counter`), never a dynamic
          `/examples/:slug` — a LiveView route maps to one module, so a single
          wildcard route can't dispatch to different LiveView modules. Verified
          routes check a dynamic interpolation by matching a placeholder
          segment against the compiled route patterns, and a literal route
          never matches a placeholder, so `~p` here would warn permanently
          under `--warnings-as-errors` regardless of how many examples are
          ready. Plain interpolation is the correct tool for this one spot.
        --%>
        <.link
          :if={@prev && @prev.status == :ready}
          navigate={"/examples/#{@prev.id}"}
          class="text-[color:var(--text-muted)] hover:text-[color:var(--text)]"
        >
          ← {@prev.title}
        </.link>
        <span :if={!@prev || @prev.status != :ready}></span>

        <.link
          :if={@next && @next.status == :ready}
          navigate={"/examples/#{@next.id}"}
          class="text-brand-strong hover:underline"
        >
          {@next.title} →
        </.link>
        <span :if={!@next || @next.status != :ready} class="text-[color:var(--text-muted)]">
          {@next && @next.title} (coming soon)
        </span>
      </footer>
    </article>
    """
  end

  defp category_of(example) do
    Enum.find_value(Examples.by_category(), "", fn %{category: category, items: items} ->
      Enum.any?(items, &(&1.id == example.id)) && category
    end)
  end

  # No file lookups here on purpose. An earlier draft resolved the extension
  # with File.exists? at render time, which works in dev and silently falls
  # back to "jsx" in a release, where assets/ does not exist. The registry
  # carries it instead.
end
