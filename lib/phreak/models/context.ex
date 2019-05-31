defmodule Phreak.Context do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contexts" do
    field :is_current, :boolean, default: false
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(context, attrs) do
    context
    |> cast(attrs, [:name, :is_current])
    |> validate_required([:name, :is_current])
  end
end
