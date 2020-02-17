defmodule EncodingTest do
  use ExUnit.Case, async: true

  test "encoding a Tuple using Jason.encode/1 outputs it as a list" do
    assert Jason.encode({5, 6}) == {:ok, "[5,6]"}
  end
end
