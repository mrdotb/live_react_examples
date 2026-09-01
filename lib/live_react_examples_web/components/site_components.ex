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
end
