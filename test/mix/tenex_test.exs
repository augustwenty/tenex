defmodule Mix.TenexTest do
  use ExUnit.Case, async: true

  @repos [Tenex.PGTestRepo]

  defmodule Repo do
    def start_link(opts) do
      assert opts[:pool_size] == 2
      Process.get(:start_link)
    end

    def __adapter__ do
      Tenex.TestAdapter
    end

    def config do
      [priv: Process.get(:priv), otp_app: :tenex]
    end
  end

  defmodule LostRepo do
    def config do
      [priv: "where", otp_app: :tenex]
    end
  end

  setup do
    for repo <- @repos do
      Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)

      drop_tenants = fn ->
        Tenex.drop("test1", repo)
        Tenex.drop("test2", repo)
      end

      drop_tenants.()
      on_exit(drop_tenants)
    end

    :ok
  end

  test "ensure tenant migrations path" do
    msg = """
    Could not find migrations directory "where/tenant_migrations"
    for repo Mix.TenexTest.LostRepo.

    This may be because you are in a new project and the
    migration directory has not been created yet. Creating an
    empty directory at the path above will fix this error.

    If you expected existing migrations to be found, please
    make sure your repository has been properly configured
    and the configured path exists.
    """

    assert_raise Mix.Error, msg, fn ->
      Mix.Tenex.ensure_tenant_migrations_path(LostRepo)
    end

    for repo <- @repos do
      folder = repo |> Module.split() |> List.last() |> Macro.underscore()

      assert Mix.Tenex.ensure_tenant_migrations_path(repo) ==
               Path.expand("priv/#{folder}/tenant_migrations")
    end
  end

  test "runs migration for each tenant, with the correct prefix" do
    for repo <- @repos do
      Tenex.create("test1", repo)
      Tenex.create("test2", repo)

      args = ["-r", repo, "--step=1", "--quiet"]

      Mix.Tenex.run_tenant_migrations(args, :down, fn ^repo, _, :down, opts ->
        assert opts[:step] == 1
        assert opts[:log] == false

        send(self(), {:ok, opts[:prefix]})

        []
      end)

      assert_received {:ok, "test1"}
      assert_received {:ok, "test2"}
    end
  end

  test "does not run if there are no tenants" do
    for repo <- @repos do
      Mix.Tenex.run_tenant_migrations(["-r", repo], :down, fn _, _, _, _ ->
        send(self(), :error)

        []
      end)

      refute_received :error
    end
  end

  test "ensure_started" do
    Application.stop(:ecto_sql)
    Logger.remove_backend(:console)
    refute :ecto_sql in Enum.map(Application.started_applications(), &elem(&1, 0))

    Process.put(:start_link, {:ok, self()})
    assert Mix.Tenex.ensure_started(Repo, []) == {:ok, self(), []}
    assert :ecto_sql in Enum.map(Application.started_applications(), &elem(&1, 0))

    Process.put(:start_link, {:error, {:already_started, self()}})
    assert Mix.Tenex.ensure_started(Repo, []) == {:ok, nil, []}

    Process.put(:start_link, {:error, self()})
    assert_raise Mix.Error, fn -> Mix.Tenex.ensure_started(Repo, []) end
  end

  test "source_priv_repo" do
    Process.put(:priv, nil)
    assert Mix.Tenex.source_repo_priv(Repo) == Path.expand("priv/repo", File.cwd!())
    Process.put(:priv, "hello")
    assert Mix.Tenex.source_repo_priv(Repo) == Path.expand("hello", File.cwd!())
  end

  test "restart_apps_if_migrated" do
    assert Mix.Tenex.restart_apps_if_migrated([:tenex], []) == :ok
    assert :tenex in Enum.map(Application.started_applications(), &elem(&1, 0))

    assert Mix.Tenex.restart_apps_if_migrated([:tenex], [1]) == :ok
    assert :tenex in Enum.map(Application.started_applications(), &elem(&1, 0))
  end
end
