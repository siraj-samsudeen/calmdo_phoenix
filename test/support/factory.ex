defmodule CalmdoPhoenix.Factory do
  @moduledoc """
  Factory module using ExMachina for generating test data.
  """
  use ExMachina.Ecto, repo: CalmdoPhoenix.Repo
end
