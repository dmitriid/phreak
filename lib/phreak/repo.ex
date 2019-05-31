defmodule Phreak.Repo do
  use Ecto.Repo,
    otp_app: :phreak,
    adapter: Ecto.Adapters.Postgres
end
