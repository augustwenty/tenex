defmodule Mix.Tasks.Triplex.MigrateTest do
  use ExUnit.Case
  import Mix.Tasks.Triplex.Migrate, only: [run: 2]

  @repos [Triplex.PGTestRepo, Triplex.MSTestRepo]

  test "runs the migrator function" do
    for repo <- @repos do
      run(["-r", repo, "--step=1", "--quiet"], fn args, direction ->
        assert args == ["-r", repo, "--step=1", "--quiet"]
        assert direction == :up
      end)
    end
  end
end
