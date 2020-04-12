exclude = [:RT]

ExUnit.start(exclude: exclude)
Ecto.Adapters.SQL.Sandbox.mode(Diep.Io.Repo, :manual)
