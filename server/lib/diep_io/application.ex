defmodule Diep.Io.Application do
  @moduledoc false

  alias Diep.Io.{GameSupervisor, PerformanceMonitor, Repo}
  alias Diep.IoWeb.{Endpoint, Presence}

  use Application

  def start(_type, _args) do
    children = [
      Repo,
      {Phoenix.PubSub, name: Diep.Io.PubSub},
      Presence,
      Endpoint,
      GameSupervisor,
      {PerformanceMonitor, :millisecond},
      Diep.IoWeb.Telemetry
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
