defmodule Diep.Io.Application do
  @moduledoc false

  alias Diep.Io.Repo, as: Repo
  alias Diep.IoWeb.Endpoint, as: Endpoint

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Repo,
      # Start the endpoint when the application starts
      Endpoint
    ]

    opts = [strategy: :one_for_one, name: Diep.Io.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
