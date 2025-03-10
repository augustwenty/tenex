# Tenex

[![Version](http://img.shields.io/hexpm/v/tenex.svg?style=flat)](https://hex.pm/packages/tenex)
[![Downloads](https://img.shields.io/hexpm/dt/tenex.svg)](https://hex.pm/packages/tenex)
[![Coverage Status](https://coveralls.io/repos/github/augustwenty/tenex/badge.svg?branch=master)](https://coveralls.io/github/augustwenty/tenex?branch=master)

A simple and effective way to build multitenant applications on top of Ecto.

[Documentation](https://hexdocs.pm/tenex/readme.html)

Tenex leverages database data segregation techniques (such as [Postgres schemas](https://www.postgresql.org/docs/current/static/ddl-schemas.html)) to keep tenant-specific data separated, while allowing you to continue using the Ecto functions you are familiar with.

## Quick Start

1. Add `tenex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tenex, "~> 1.0.0"},
  ]
end
```

2. Run in your shell:

```bash
mix deps.get
```

## Configuration

Configure the Repo you will use to execute the database commands within your config/config.exs file:

    config :tenex, repo: ExampleApp.Repo

## Usage

Here is a quick overview of what you can do with tenex!

### Creating, renaming and dropping tenants

#### To create a new tenant:

```elixir
Tenex.create("your_tenant")
```

This will create a new database schema and run your migrations — which may take a while depending on your application.

#### Rename a tenant:

```elixir
Tenex.rename("your_tenant", "my_tenant")
```

This is not something you should need to do often. :-)

#### Delete a tenant:

```elixir
Tenex.drop("my_tenant")
```

More information on the API can be found in [documentation](https://hexdocs.pm/tenex/Tenex.html#content).

### Creating tenant migrations

To create a migration to run across tenant schemas:

```bash
mix tenex.gen.migration your_migration_name
```

If migrating an existing project to use Tenex, you can move some or all of your existing migrations from `priv/YOUR_REPO/migrations` to `priv/YOUR_REPO/tenant_migrations`.

Tenex and Ecto will automatically add prefixes to standard migration functions. If you have _custom_ SQL in your migrations, you will need to use the [`prefix`](https://hexdocs.pm/ecto/Ecto.Migration.html#prefix/0) function provided by Ecto. e.g.

```elixir
def up do
  execute "CREATE INDEX name_trgm_index ON #{prefix()}.users USING gin (nam gin_trgm_ops);"
end
```

### Running tenant migrations:

```bash
mix tenex.migrate
```

This will migrate all of your existing tenants, one by one. In the case of failure, the next run will continue from where it stopped.

### Using Ecto

Your Ecto usage only needs the `prefix` option. Tenex provides a helper to coerce the tenant value into the proper format, e.g.:

```elixir
Repo.all(User, prefix: Tenex.to_prefix("my_tenant"))
Repo.get!(User, 123, prefix: Tenex.to_prefix("my_tenant"))
```

### Fetching the tenant with Plug

Tenex includes configurable plugs that you can use to load the current tenant in your application.

Here is an example loading the tenant from the current subdomain:

```elixir
plug Tenex.SubdomainPlug, endpoint: MyApp.Endpoint
```

For more information, check the `Tenex.Plug` documentation for an overview of our plugs.

## Thanks

This lib is inspired by the gem [apartment](https://github.com/influitive/apartment), which does the same thing in Ruby on Rails world. We also give credit (and a lot of thanks) to @Dania02525 for the work on [apartmentex](https://github.com/Dania02525/apartmentex). A lot of the work here is based on what she has done there. And also to @jeffdeville, who forked ([tenantex](https://github.com/jeffdeville/tenantex)) taking a different approach, which gave us additional ideas.
