defmodule ZclassicExplorer.Repo do
  use Ecto.Repo,
    otp_app: :zclassic_explorer,
    adapter: Ecto.Adapters.Postgres
end
