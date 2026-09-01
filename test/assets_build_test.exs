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

  test "semantic tokens are defined for both themes", %{css: css} do
    assert css =~ "--surface"
    assert css =~ "--text-muted"
    # the dark variant must actually emit a rule, not just be declared
    assert css =~ ".dark"
  end

  test "shadcn aliases the existing components rely on still resolve", %{css: css} do
    for token <- ~w(--background --foreground --card --muted-foreground --border --ring --radius) do
      assert css =~ token, "missing #{token}; card/tabs/button components reference it"
    end
  end

  test "--primary meets WCAG AA contrast with white --primary-foreground", %{css: css} do
    # 18 100% 50% (light) / 18 100% 55% (dark) measured ~3.3:1 and ~3.1:1
    # against white text -- below the 4.5:1 AA minimum for normal text on
    # bg-primary/text-primary-foreground buttons and badges. 18 100% 40%
    # keeps the brand hue/saturation and measures 4.95:1 in both themes.
    # Pinning the emitted value here catches a future palette edit that
    # silently reintroduces the failure.
    primary_occurrences = css |> String.split("--primary:") |> length() |> Kernel.-(1)
    assert primary_occurrences == 2, "expected --primary in both :root and .dark"

    assert css
           |> String.split("--primary:")
           |> Enum.drop(1)
           |> Enum.all?(&String.starts_with?(&1, "18 100% 40%"))
  end
end

defmodule LiveReactExamples.AssetsDepsTest do
  use ExUnit.Case, async: true

  test "only one syntax highlighter is a dependency" do
    package_json =
      Path.expand("../assets/package.json", __DIR__) |> File.read!() |> Jason.decode!()

    deps = Map.get(package_json, "dependencies", %{})

    assert Map.has_key?(deps, "highlight.js"), "highlight.js is the one in use"
    refute Map.has_key?(deps, "prism-react-renderer")
    refute Map.has_key?(deps, "react-syntax-highlighter")
  end
end
