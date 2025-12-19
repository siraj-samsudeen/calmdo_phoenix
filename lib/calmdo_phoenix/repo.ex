defmodule CalmdoPhoenix.Repo do
  use Ecto.Repo,
    otp_app: :calmdo_phoenix,
    adapter: Ecto.Adapters.Postgres
end
