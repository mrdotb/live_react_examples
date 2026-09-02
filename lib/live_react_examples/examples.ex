defmodule LiveReactExamples.Examples do
  @moduledoc """
  Catalog of every LiveReact example.

  The single source of truth: the sidebar, the index page, the router, the
  prev/next footer and the tests all derive from this list, so adding an
  example means adding one entry here plus its two source files.

  `kind` distinguishes the two ways LiveReact is used, which is itself one of
  the things the site demonstrates:

    * `:live` — the preview is a LiveView, rendered as a child via
      `live_render/3`.
    * `:dead` — the preview is a controller-rendered page with no socket. The
      point of these examples is that React works without a LiveView, so they
      are rendered inline and offered as a standalone route rather than being
      wrapped in a LiveView, which would destroy what they demonstrate.

  `status` is `:ready` when the example has been migrated to the two-module
  convention and has a route. `:planned` entries appear in the index greyed
  out and have no route.
  """

  @examples [
    %{
      category: "Getting Started",
      items: [
        %{
          id: "counter",
          title: "Counter",
          description: "Assigns become props; clicks become handle_event",
          icon: "hero-plus-circle",
          kind: :live,
          module: "Counter",
          react_ext: "jsx",
          features: ["props", "phx-click", "local state"],
          status: :ready
        },
        %{
          id: "simple",
          title: "Hello React",
          description: "Render a component from a controller, with no socket",
          icon: "hero-sparkles",
          kind: :dead,
          module: "Simple",
          react_ext: "jsx",
          features: ["dead view", "SSR"],
          status: :ready
        },
        %{
          id: "simple-props",
          title: "Props",
          description: "Pass values from a template into a component",
          icon: "hero-arrow-right-circle",
          kind: :dead,
          module: "SimpleProps",
          react_ext: "jsx",
          features: ["dead view", "props"],
          status: :ready
        }
      ]
    },
    %{
      category: "Events",
      items: [
        %{
          id: "events",
          title: "Event Handling",
          description: "pushEvent from React reaches handle_event on the server",
          icon: "hero-cursor-arrow-rays",
          kind: :live,
          module: "Events",
          react_ext: "jsx",
          features: ["useLiveReact", "pushEvent"],
          status: :ready
        },
        %{
          id: "server-events",
          title: "Server Events",
          description: "push_event on the server reaches handleEvent in React",
          icon: "hero-bell-alert",
          kind: :live,
          module: "ServerEvents",
          react_ext: "jsx",
          features: ["push_event", "handleEvent", "toasts"],
          status: :planned
        }
      ]
    },
    %{
      category: "Props & data",
      items: [
        %{
          id: "streams",
          title: "Phoenix Streams",
          description: "A stream assign arrives in React as an array with __dom_id",
          icon: "hero-signal",
          kind: :live,
          module: "Streams",
          react_ext: "jsx",
          features: ["stream/4", "__dom_id"],
          status: :planned
        }
      ]
    },
    %{
      category: "Forms",
      items: [
        %{
          id: "hybrid-form",
          title: "Hybrid Form",
          description: "A LiveView form with a React control inside it",
          icon: "hero-adjustments-horizontal",
          kind: :live,
          module: "HybridForm",
          react_ext: "jsx",
          features: ["forms", "Phoenix.HTML.Form encoder"],
          status: :planned
        }
      ]
    },
    %{
      category: "Navigation",
      items: [
        %{
          id: "link",
          title: "Link",
          description: "The Link component for href, patch and navigate",
          icon: "hero-link",
          kind: :live,
          module: "Link",
          react_ext: "jsx",
          features: ["Link", "patch", "navigate"],
          status: :planned
        },
        %{
          id: "link-demo",
          title: "Patch vs Navigate",
          description: "What each navigation mode actually does to the socket",
          icon: "hero-arrows-right-left",
          kind: :live,
          module: "LinkDemo",
          react_ext: "jsx",
          features: ["Link", "handle_params"],
          status: :planned
        }
      ]
    },
    %{
      category: "Advanced",
      items: [
        %{
          id: "ssr",
          title: "SSR Control",
          description: "Turn server rendering off for browser-only components",
          icon: "hero-server",
          kind: :live,
          module: "SSR",
          react_ext: "jsx",
          features: ["ssr={false}"],
          status: :planned
        },
        %{
          id: "slots",
          title: "Slots",
          description: "HEEx markup passed into React as children",
          icon: "hero-puzzle-piece",
          kind: :live,
          module: "Slots",
          react_ext: "jsx",
          features: ["inner_block", "children"],
          status: :planned
        },
        %{
          id: "context",
          title: "React Context",
          description: "Share state between components without prop drilling",
          icon: "hero-share",
          kind: :live,
          module: "Context",
          react_ext: "jsx",
          features: ["context", "local state"],
          status: :planned
        },
        %{
          id: "typescript",
          title: "TypeScript",
          description: "Typed props in a .tsx component",
          icon: "hero-code-bracket",
          kind: :dead,
          module: "Typescript",
          react_ext: "tsx",
          features: ["dead view", "TypeScript"],
          status: :ready
        },
        %{
          id: "lazy",
          title: "Lazy Loading",
          description: "React.lazy and Suspense inside LiveView",
          icon: "hero-clock",
          kind: :dead,
          module: "Lazy",
          react_ext: "jsx",
          features: ["dead view", "React.lazy", "Suspense"],
          status: :ready
        }
      ]
    }
  ]

  @flat Enum.flat_map(@examples, & &1.items)

  @doc "Every example, in display order."
  def all, do: @flat

  @doc "Examples grouped into their categories, in display order."
  def by_category, do: @examples

  @doc "Only the examples that have been migrated and have a route."
  def ready, do: Enum.filter(@flat, &(&1.status == :ready))

  @doc "Looks an example up by slug."
  def fetch(id) do
    case Enum.find(@flat, &(&1.id == id)) do
      nil -> :error
      example -> {:ok, example}
    end
  end

  @doc """
  The examples either side of `id` in display order, for the prev/next footer.
  Returns `{nil, next}` at the start and `{prev, nil}` at the end.
  """
  def neighbours(id) do
    index = Enum.find_index(@flat, &(&1.id == id))

    case index do
      nil -> {nil, nil}
      0 -> {nil, Enum.at(@flat, 1)}
      i -> {Enum.at(@flat, i - 1), Enum.at(@flat, i + 1)}
    end
  end
end
