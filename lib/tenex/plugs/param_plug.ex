if Code.ensure_loaded?(Plug) do
  defmodule Tenex.ParamPlug do
    @moduledoc """
    This is a basic plug that loads the current tenant assign from a given
    param.

    To plug it on your router, you can use:

        plug Tenex.ParamPlug,
          param: :subdomain,
          tenant_handler: &TenantHelper.tenant_handler/1

    See `Tenex.ParamPlugConfig` to check all the allowed `config` flags.
    """

    alias Tenex.ParamPlugConfig
    alias Tenex.Plug

    @doc false
    def init(opts), do: struct(ParamPlugConfig, opts)

    @doc false
    def call(conn, config), do: Plug.put_tenant(conn, get_param(conn, config), config)

    defp get_param(conn, %ParamPlugConfig{param: key}),
      do: get_param(conn, key)

    defp get_param(conn, key) when is_atom(key),
      do: get_param(conn, Atom.to_string(key))

    defp get_param(conn, key),
      do: conn.params[key]
  end
end
