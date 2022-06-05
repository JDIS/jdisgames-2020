defmodule DiepIOWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn {error_msg, _opts} ->
      content_tag(:span, error_msg, class: "help-block")
    end)
  end
end
