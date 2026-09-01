defmodule LiveReactExamples.AssetsBuildTest do
  @moduledoc """
  Compiles the real stylesheet through Vite and asserts the Tailwind 4 CSS
  pipeline still produces our tokens. Tagged :assets because it shells out to
  npm and takes several seconds; run with `mix test --include assets`.
  """
  use ExUnit.Case, async: false

  @moduletag :assets
  @moduletag timeout: 180_000

  setup_all do
    {output, status} =
      System.cmd("npm", ["run", "build"],
        cd: Path.expand("../assets", __DIR__),
        stderr_to_stdout: true
      )

    assert status == 0, "asset build failed:\n#{output}"
    css = Path.expand("../priv/static/assets/app.css", __DIR__)
    assert File.exists?(css), "expected built stylesheet at #{css}"
    {:ok, css: File.read!(css)}
  end

  test "palette tokens are emitted", %{css: css} do
    assert css =~ "#FD4F00" or css =~ "#fd4f00"
    assert css =~ "#61DAFB" or css =~ "#61dafb"
  end

  test "heroicon masks are still bundled", %{css: css} do
    assert css =~ "--hero-arrow-path"
  end

  test "no legacy tailwind js config remains" do
    refute File.exists?(Path.expand("../assets/tailwind.config.js", __DIR__))
  end

  test "semantic color utilities used by core_components still resolve", %{css: css} do
    # Guards the @theme mapping (--color-card, --color-muted, etc. -> hsl(var(--card)),
    # ...) that replaced tailwind.config.js's theme.extend.colors. Assert on the
    # actual generated class rules, not just the presence of the --color-* tokens,
    # so this fails if the mapping stops producing utilities the app depends on.
    assert css =~ ~r/\.bg-card\{[^}]*background-color:\s*var\(--color-card\)/
    assert css =~ ~r/\.text-card-foreground\{[^}]*color:\s*var\(--color-card-foreground\)/
    assert css =~ ~r/\.bg-muted\{[^}]*background-color:\s*var\(--color-muted\)/
    assert css =~ ~r/\.bg-background\{[^}]*background-color:\s*var\(--color-background\)/
    assert css =~ ~r/\.bg-primary\{[^}]*background-color:\s*var\(--color-primary\)/
    assert css =~ ~r/ring-ring[^{]*\{[^}]*--tw-ring-color:\s*var\(--color-ring\)/
  end
end
