defmodule Diep.IoWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # VM Metrics
      last_value("vm.memory.total", unit: :byte),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.total_run_queue_lengths.io"),
      last_value("my_app.worker.memory", unit: :byte),
      last_value("my_app.worker.message_queue_len"),

      # Database Time Metrics
      summary("my_app.repo.query.total_time", unit: {:native, :millisecond}),
      summary("my_app.repo.query.decode_time", unit: {:native, :millisecond}),
      summary("my_app.repo.query.query_time", unit: {:native, :millisecond}),
      summary("my_app.repo.query.queue_time", unit: {:native, :millisecond}),

      # Phoenix Time Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        unit: {:native, :millisecond},
        tags: [:plug]
      ),

      # Game Metrics
      summary("game.performance.broadcast_time",
        unit: {:native, :millisecond},
        description: "Delay between broadcasts",
        reporter_options: [test: "haha"]
      ),
      last_value("game.performance.broadcast_time_std_dev"),
      summary("game.performance.iteration_duration", unit: {:native, :millisecond})
    ]
  end

  def periodic_measurements do
    [
      {Diep.Io.PerformanceMonitor, :get_broadcast_stats, []}
    ]
  end
end
