defmodule DiepIO.PubSub do
  @moduledoc """
  Simple wrapper around `Phoenix.PubSub` that abstracts the pubsub's name.
  """

  alias Phoenix.PubSub

  @spec subscribe(PubSub.topic()) :: :ok | {:error, any()}
  def subscribe(topic), do: PubSub.subscribe(__MODULE__, topic)

  @spec broadcast!(PubSub.topic(), PubSub.message()) :: :ok
  def broadcast!(topic, message), do: PubSub.broadcast!(__MODULE__, topic, message)
end
