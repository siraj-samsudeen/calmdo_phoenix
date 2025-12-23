defmodule CalmdoPhoenix.Factory do
  @moduledoc """
  Factory module using ExMachina for generating test data.
  """
  use ExMachina.Ecto, repo: CalmdoPhoenix.Repo
  alias CalmdoPhoenix.Projects.Project
  alias CalmdoPhoenix.Accounts.User
  alias CalmdoPhoenix.Accounts.Scope

  def project_factory do
    %Project{
      name: "#{System.unique_integer([:positive])} - #{Faker.Company.name()}",
      description: sequence(:description, &"Description #{&1}")
    }
  end

  # TODO: is this the right way to create a user? In ConnCase, it does it differently.
  def scope_factory do
    Scope.for_user(%User{
      email: sequence(:email, &"user#{&1}@example.com"),
      password: "password"
    })
  end
end
