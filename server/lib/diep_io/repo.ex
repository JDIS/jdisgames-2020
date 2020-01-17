defmodule Diep.Io.Repo do
  use Ecto.Repo,
    otp_app: :diep_io,
    adapter: Ecto.Adapters.Postgres
end
