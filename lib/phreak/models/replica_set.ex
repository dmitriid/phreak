defmodule Phreak.ReplicaSet do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uid, :string, autogenerate: false}
  schema "replica_sets" do
    field :name, :string
    field :status, :string

    timestamps()
  end

  @doc false
  def changeset(replica_set, attrs) do
    replica_set
    |> cast(attrs, [:uid, :name, :status])
    |> validate_required([:uid, :name, :status])
  end
end
