if Code.ensure_loaded?(Plug) do
  defmodule Tenex.SessionPlug do
    @moduledoc """
    This is a basic plug that loads the current tenant assign from a given
    value set on session.

    To plug it on your router, you can use:

        plug Tenex.SessionPlug,
          session: :subdomain,
          tenant_handler: &TenantHelper.tenant_handler/1

    See `Tenex.SessionPlugConfig` to check all the allowed `config` flags.
    """

    alias Plug.Conn

    alias Tenex.Plug
    alias Tenex.SessionPlugConfig

    @doc false
    def init(opts), do: struct(SessionPlugConfig, opts)

    @doc false
    def call(conn, config) do
      Plug.put_tenant(conn, Conn.get_session(conn, config.session), config)
    end
  end
end
