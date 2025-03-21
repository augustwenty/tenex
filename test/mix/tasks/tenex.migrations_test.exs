defmodule Mix.Tasks.Tenex.MigrationsTest do
  use ExUnit.Case

  alias Mix.Tasks.Tenex.Migrations
  alias Ecto.Migrator

  @repos [Tenex.PGTestRepo]

  setup do
    for repo <- @repos do
      Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)

      drop_tenants = fn ->
        Tenex.drop("migrations_test_down", repo)
        Tenex.drop("migrations_test_up", repo)
      end

      drop_tenants.()
      on_exit(drop_tenants)
    end

    :ok
  end

  test "runs migration for each tenant, with the correct prefix" do
    for repo <- @repos do
      Tenex.create_schema("migrations_test_down", repo)
      Tenex.create("migrations_test_up", repo)

      Migrations.run(["-r", repo], &Migrator.migrations/2, fn msg ->
        assert msg =~
                 """
                 Repo: #{inspect(repo)}
                 Tenant: migrations_test_down

                   Status    Migration ID    Migration Name
                 --------------------------------------------------
                   down      20160711125401  test_create_tenant_notes
                 """

        assert msg =~
                 """
                 Repo: #{inspect(repo)}
                 Tenant: migrations_test_up

                   Status    Migration ID    Migration Name
                 --------------------------------------------------
                   up        20160711125401  test_create_tenant_notes
                 """
      end)
    end
  end
end
