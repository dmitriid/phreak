defmodule Phreak.Job do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uid, :string, autogenerate: false}
  schema "jobs" do
    field :name, :string
    field :status, :string

    timestamps()
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:uid, :name, :status])
    |> validate_required([:uid, :name, :status])
  end
end
