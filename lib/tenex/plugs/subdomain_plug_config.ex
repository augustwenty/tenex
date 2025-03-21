defmodule Tenex.SubdomainPlugConfig do
  @moduledoc """
  This is a struct that holds the configuration for `Tenex.SubdomainPlug`.

  Here are the config keys allowed:

  - `tenant_handler`: function to handle the tenant param. Its return will
  be used as the tenant.
  - `assign`: the name of the assign where we must save the tenant.
  - `endpoint`: the Phoenix.Endpoint to get the host name to discover the
  subdomain.
  """

  defstruct [
    :endpoint,
    :tenant_handler,
    assign: :current_tenant
  ]
end
