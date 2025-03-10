defmodule Tenex.FakeEndpoint do
  def config(:url), do: %{host: "lvh.me"}
end
