defmodule LiveReactExamplesWeb.CoreComponentsTest do
  @moduledoc """
  Guards the boundary between components the site actually renders and the
  Phoenix generator scaffolding it never did.
  """
  use ExUnit.Case, async: true

  alias LiveReactExamplesWeb.CoreComponents

  # function_exported?/3 only inspects already-loaded modules; it never
  # triggers autoloading. Ensure CoreComponents is loaded so both tests below
  # reflect its actual exports rather than module-load ordering.
  setup_all do
    Code.ensure_loaded!(CoreComponents)
    :ok
  end

  @removed [
    modal: 1,
    show_modal: 1,
    show_modal: 2,
    hide_modal: 1,
    hide_modal: 2,
    table: 1,
    list: 1,
    back: 1
  ]

  @kept [
    flash: 1,
    flash_group: 1,
    icon: 1,
    button: 1,
    a: 1,
    header: 1,
    simple_form: 1,
    input: 1,
    label: 1,
    error: 1,
    tabs: 1,
    tabs_list: 1,
    tabs_trigger: 1,
    tabs_content: 1,
    card: 1,
    card_content: 1,
    border_beam: 1,
    show: 1,
    show: 2,
    hide: 1,
    hide: 2
  ]

  test "unused generator scaffolding is gone" do
    for {fun, arity} <- @removed do
      refute function_exported?(CoreComponents, fun, arity),
             "#{fun}/#{arity} is dead code and should have been removed"
    end
  end

  test "components the site renders are still exported" do
    for {fun, arity} <- @kept do
      assert function_exported?(CoreComponents, fun, arity),
             "#{fun}/#{arity} is used by the site and must not be removed"
    end
  end
end
