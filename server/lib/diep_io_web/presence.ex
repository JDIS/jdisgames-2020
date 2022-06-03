defmodule DiepIOWeb.Presence do
  @moduledoc false

  use Phoenix.Presence,
    otp_app: :diep_io_web,
    pubsub_server: DiepIO.PubSub
end
