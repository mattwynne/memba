defmodule MembaWeb.PersonNameTransitionTest do
  use ExUnit.Case, async: true

  test "blank-name rejection has the approved field feedback" do
    assert MembaWeb.PersonNameTransition.error_message(:invalid_name) ==
             "Enter the name your clubs should see."
  end
end
