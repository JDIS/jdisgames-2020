exclude = [:RT]

ExUnit.start(exclude: exclude)
Ecto.Adapters.SQL.Sandbox.mode(DiepIO.Repo, :manual)
