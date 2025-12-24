defmodule CalmdoPhoenix.Factory do
  @moduledoc """
  Factory module using ExMachina for generating test data.
  """
  use ExMachina.Ecto, repo: CalmdoPhoenix.Repo
  alias CalmdoPhoenix.Projects.Project

  def project_factory do
    %Project{
      name: "#{System.unique_integer([:positive])} - #{Faker.Company.name()}",
      description: sequence(:description, &"Description #{&1}")
    }
  end
end
