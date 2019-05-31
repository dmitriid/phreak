defmodule Phreak.Models.Mapping do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phreak.Mapping

  @primary_key {:uid, :string, autogenerate: false}
  schema "mappings" do
    field :name, :string
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(mapping, attrs) do
    mapping
    |> cast(attrs, [:uid, :name, :type])
    |> validate_required([:uid, :name, :type])
  end
end
