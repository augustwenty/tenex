if Code.ensure_loaded?(Plug) do
  defmodule Tenex.EnsurePlug do
    @moduledoc """
    This is a basic plug that ensure the tenant is loaded.

    To plug it on your router, you can use:

        plug Tenex.EnsurePlug,
          callback: &TenantHelper.callback/2
          failure_callback: &TenantHelper.failure_callback/2

    See `Tenex.EnsurePlugConfig` to check all the allowed `config` flags.
    """

    alias Tenex.EnsurePlugConfig
    alias Tenex.Plug

    @doc false
    def init(opts), do: struct(EnsurePlugConfig, opts)

    @doc false
    def call(conn, config), do: Plug.ensure_tenant(conn, config)
  end
end
