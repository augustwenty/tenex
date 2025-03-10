defmodule TenexTest do
  use ExUnit.Case

  alias Tenex.Note
  alias Tenex.PGTestRepo

  @migration_version 20_160_711_125_401
  @repos [PGTestRepo]
  @tenant "trilegal"

  setup do
    for repo <- @repos do
      Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)

      drop_tenants = fn ->
        Tenex.drop("lala", repo)
        Tenex.drop("lili", repo)
        Tenex.drop("lolo", repo)
        Tenex.drop(@tenant, repo)
      end

      drop_tenants.()
      on_exit(drop_tenants)
    end

    :ok
  end

  test "create/2 must create a new tenant" do
    for repo <- @repos do
      Tenex.create("lala", repo)
      assert Tenex.exists?("lala", repo)
    end
  end

  test "create/2 must return a error if the tenant already exists" do
    assert {:ok, _} = Tenex.create("lala", PGTestRepo)

    assert {:error, message} =
             Tenex.create("lala", PGTestRepo)

    assert message =~ "ERROR 42P06 (duplicate_schema) schema \"lala\" already exists"
  end

  test "create/2 must return a error if the tenant is reserved" do
    for repo <- @repos do
      assert {:error, msg} = Tenex.create("www", repo)

      assert msg ==
               """
               You cannot create the schema because \"www\" is a reserved
               tenant
               """
    end
  end

  test "create_schema/3 must rollback the tenant creation when function fails" do
    for repo <- @repos do
      result = {:error, "message"}

      assert Tenex.create_schema("lala", repo, fn "lala", ^repo ->
               assert Tenex.exists?("lala", repo)
               result
             end) == result

      refute Tenex.exists?("lala", repo)
    end
  end

  test "drop/2 must drop a existent tenant" do
    for repo <- @repos do
      Tenex.create("lala", repo)
      Tenex.drop("lala", repo)
      refute Tenex.exists?("lala", repo)
    end
  end

  test "rename/3 must drop a existent tenant" do
    Tenex.create("lala", PGTestRepo)
    Tenex.rename("lala", "lolo", PGTestRepo)
    refute Tenex.exists?("lala", PGTestRepo)
    assert Tenex.exists?("lolo", PGTestRepo)
  end

  test "all/1 must return all tenants" do
    for repo <- @repos do
      Tenex.create("lala", repo)
      Tenex.create("lili", repo)
      Tenex.create("lolo", repo)
      assert MapSet.new(Tenex.all(repo)) == MapSet.new(["lala", "lili", "lolo"])
    end
  end

  test "exists?/2 for a not created tenant returns false" do
    for repo <- @repos do
      refute Tenex.exists?("lala", repo)
      refute Tenex.exists?("lili", repo)
      refute Tenex.exists?("lulu", repo)
    end
  end

  test "exists?/2 for a reserved tenants returns false" do
    for repo <- @repos do
      tenants = Enum.filter(Tenex.reserved_tenants(), &(!is_struct(&1, Regex)))
      tenants = ["pg_lol", "pg_cow" | tenants]

      for tenant <- tenants do
        refute Tenex.exists?(tenant, repo)
      end
    end
  end

  test "reserved_tenant?/1 returns if the given tenant is reserved" do
    assert Tenex.reserved_tenant?(%{id: "www"}) == true
    assert Tenex.reserved_tenant?("www") == true
    assert Tenex.reserved_tenant?(%{id: "bla"}) == false
    assert Tenex.reserved_tenant?("bla") == false
  end

  test "migrations_path/1 must return the tenant migrations path" do
    for repo <- @repos do
      folder = repo |> Module.split() |> List.last() |> Macro.underscore()
      expected = Application.app_dir(:tenex, "priv/#{folder}/tenant_migrations")
      assert Tenex.migrations_path(repo) == expected
    end
  end

  test "migrate/2 migrates the tenant forward by default" do
    for repo <- @repos do
      create_tenant_schema(repo)

      assert_creates_notes_table(repo, fn ->
        {status, versions} = Tenex.migrate(@tenant, repo)

        assert status == :ok
        assert versions == [@migration_version]
      end)
    end
  end

  test "migrate/2 returns an error tuple when it fails" do
    for repo <- @repos do
      create_and_migrate_tenant(repo)

      force_migration_failure(repo, fn expected_error ->
        {status, error_message} = Tenex.migrate(@tenant, repo)
        assert status == :error
        assert error_message =~ expected_error
      end)
    end
  end

  test "to_prefix/2 must apply the given prefix to the tenant name" do
    assert Tenex.to_prefix("a", nil) == "a"
    assert Tenex.to_prefix(%{id: "a"}, nil) == "a"
    assert Tenex.to_prefix("a", "b") == "ba"
    assert Tenex.to_prefix(%{id: "a"}, "b") == "ba"
  end

  defp assert_creates_notes_table(repo, fun) do
    assert_notes_table_is_dropped(repo)
    fun.()
    assert_notes_table_is_present(repo)
  end

  defp assert_notes_table_is_dropped(repo) do
    error =
      case repo.__adapter__() do
        Ecto.Adapters.MyXQL -> MyXQL.Error
        Ecto.Adapters.Postgres -> Postgrex.Error
      end

    assert_raise error, fn ->
      find_tenant_notes(repo)
    end
  end

  defp assert_notes_table_is_present(repo) do
    assert find_tenant_notes(repo) == []
  end

  defp create_and_migrate_tenant(repo) do
    Tenex.create(@tenant, repo)
  end

  defp create_tenant_schema(repo) do
    Tenex.create_schema(@tenant, repo)
  end

  defp find_tenant_notes(repo) do
    query =
      Note
      |> Ecto.Queryable.to_query()
      |> Map.put(:prefix, @tenant)

    repo.all(query)
  end

  defp force_migration_failure(repo, migration_function) do
    sql =
      """
      DELETE FROM "#{@tenant}"."schema_migrations"
      """

    {:ok, _} = Ecto.Adapters.SQL.query(repo, sql, [])

    migration_function.("ERROR 42P07 (duplicate_table) relation \"notes\" already exists")
  end
end
