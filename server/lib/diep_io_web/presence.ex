defmodule Diep.IoWeb.Presence do
  @moduledoc false

  use Phoenix.Presence,
    otp_app: :diep_io_web,
    pubsub_server: Diep.Io.PubSub
end
