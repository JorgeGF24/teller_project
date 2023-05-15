defmodule GenericAppBackendTest do
  use ExUnit.Case
  doctest GenericAppBackend

  test "greets the world" do
    assert GenericAppBackend.hello() == :world
  end
end
