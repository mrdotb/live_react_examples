defmodule LiveReactExamplesWeb.SiteComponents do
  @moduledoc """
  Chrome shared by every page: header, footer and theme toggle.

  Kept separate from `CoreComponents` (generic building blocks) because these
  are specific to this site's layout.
  """
  use Phoenix.Component

  # Verified routes are declared explicitly rather than via
  # `use LiveReactExamplesWeb, :html`: html_helpers imports this module, so
  # using it here would be a compile cycle.
  use Phoenix.VerifiedRoutes,
    endpoint: LiveReactExamplesWeb.Endpoint,
    router: LiveReactExamplesWeb.Router,
    statics: LiveReactExamplesWeb.static_paths()

  import LiveReactExamplesWeb.CoreComponents, only: [icon: 1]

  @doc """
  Light/dark toggle.

  Writes the choice to localStorage under "theme" and flips the `.dark` class
  on `<html>`. The initial class is set by the inline script in the root
  layout, not here, so the page never paints the wrong theme first.
  """
  attr :class, :string, default: nil

  def theme_toggle(assigns) do
    ~H"""
    <button
      id="theme-toggle"
      type="button"
      aria-label="Toggle dark mode"
      class={[
        "inline-flex h-9 w-9 items-center justify-center rounded-md",
        "text-[color:var(--text-muted)] hover:text-[color:var(--text)]",
        "hover:bg-[color:var(--surface-raised)] transition-colors",
        @class
      ]}
      phx-update="ignore"
      onclick="window.__toggleTheme()"
    >
      <.icon name="hero-sun" class="h-5 w-5 dark:hidden" />
      <.icon name="hero-moon" class="hidden h-5 w-5 dark:block" />
    </button>
    """
  end

  @github "https://github.com/mrdotb/live_react"
  @hexdocs "https://hexdocs.pm/live_react"

  @doc """
  Sticky site header: logo, primary nav, star badge and theme toggle.
  """
  attr :class, :string, default: nil

  def site_header(assigns) do
    assigns = assign(assigns, github: @github, hexdocs: @hexdocs)

    ~H"""
    <header class={[
      "sticky top-0 z-50 h-14 w-full",
      "border-b border-[color:var(--edge)]",
      "bg-[color:var(--surface)]/80 backdrop-blur",
      @class
    ]}>
      <div class="mx-auto flex h-full max-w-screen-2xl items-center justify-between px-8">
        <div class="flex items-center gap-4">
          <a href="/" class="flex items-center">
            <img src={~p"/images/logo.svg"} class="w-32" alt="LiveReact" />
          </a>
          <p class="hidden rounded-full bg-brand/10 px-2 font-medium leading-6 text-brand-strong sm:block">
            examples
          </p>
        </div>

        <nav class="flex items-center gap-2 text-sm">
          <.link
            href={~p"/examples"}
            class="rounded-md px-3 py-1.5 text-[color:var(--text-muted)] hover:text-[color:var(--text)]"
          >
            Examples
          </.link>
          <a
            href={@hexdocs}
            class="rounded-md px-3 py-1.5 text-[color:var(--text-muted)] hover:text-[color:var(--text)]"
          >
            Docs
          </a>
          <a
            href={@github}
            class="rounded-md px-3 py-1.5 text-[color:var(--text-muted)] hover:text-[color:var(--text)]"
          >
            GitHub
          </a>
          <img
            src="https://img.shields.io/github/stars/mrdotb/live_react?logo=github&logoColor=000000&label=Star&color=fafafa&style=social"
            alt="GitHub stars"
            class="ml-1 hidden md:block"
          />
          <.theme_toggle class="ml-1" />
        </nav>
      </div>
    </header>
    """
  end

  @doc """
  Site footer.
  """
  attr :class, :string, default: nil

  def site_footer(assigns) do
    assigns = assign(assigns, github: @github, hexdocs: @hexdocs)

    ~H"""
    <footer class={[
      "mt-16 border-t border-[color:var(--edge)] py-10",
      "text-sm text-[color:var(--text-muted)]",
      @class
    ]}>
      <div class="mx-auto flex max-w-screen-2xl flex-col gap-2 px-8 sm:flex-row sm:justify-between">
        <p>
          Demo application for
          <a href={@github} class="text-brand-strong hover:underline">LiveReact</a>
          — React components inside Phoenix LiveView.
        </p>
        <div class="flex gap-4">
          <a href={@hexdocs} class="hover:text-[color:var(--text)]">Documentation</a>
          <a href={@github} class="hover:text-[color:var(--text)]">Source</a>
          <a href="https://github.com/mrdotb" class="hover:text-[color:var(--text)]">@mrdotb</a>
        </div>
      </div>
    </footer>
    """
  end
end
