defmodule Tenex.EnsurePlugTest do
  use ExUnit.Case

  import Plug.Test
  alias Tenex.EnsurePlug

  test "call/2 calls callback on success" do
    callback = fn conn, _ -> Plug.Conn.assign(conn, :lala, "lolo") end

    conn =
      :get
      |> conn("/")
      |> Plug.Conn.assign(:current_tenant, "lele")
      |> EnsurePlug.call(EnsurePlug.init(callback: callback))

    assert conn.assigns[:current_tenant] == "lele"
    assert conn.assigns[:lala] == "lolo"
  end

  test "call/2 call failure callback on fail" do
    callback = fn conn, _ -> Plug.Conn.assign(conn, :lele, "lili") end

    conn =
      :get
      |> conn("/", lol: "")
      |> EnsurePlug.call(EnsurePlug.init(failure_callback: callback))

    assert conn.assigns[:current_tenant] == nil
    assert conn.assigns[:lele] == "lili"
    assert conn.halted == true
  end
end
