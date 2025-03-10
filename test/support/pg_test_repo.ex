defmodule Tenex.PGTestRepo do
  use Ecto.Repo, otp_app: :tenex, adapter: Ecto.Adapters.Postgres
end
