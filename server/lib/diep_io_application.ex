defmodule DiepIOApplication do
  @moduledoc false

  use Boundary, deps: [DiepIO, DiepIOWeb], exports: []

  use Application

  alias DiepIO.{GameSupervisor, PerformanceMonitor, Repo}
  alias DiepIOWeb.{Endpoint, Presence}

  def start(_type, _args) do
    children = [
      Repo,
      {Phoenix.PubSub, name: DiepIO.PubSub},
      Presence,
      Endpoint,
      GameSupervisor,
      {PerformanceMonitor, :millisecond},
      DiepIOWeb.Telemetry
    ]

    opts = [strategy: :one_for_one, name: DiepIO.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
