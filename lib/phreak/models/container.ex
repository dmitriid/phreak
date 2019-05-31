defmodule Phreak.Container do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uid, :string, autogenerate: false}
  schema "containers" do
    field :name, :string
    field :status, :string
    field :parent_uid, :string

    timestamps()
  end

  @doc false
  def changeset(container, attrs) do
    container
    |> cast(attrs, [:uid, :name, :status])
    |> validate_required([:uid, :name, :status])
  end
end
