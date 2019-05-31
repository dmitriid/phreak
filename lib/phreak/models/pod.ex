defmodule Phreak.Models.Pod do
  use Ecto.Schema
  import Ecto.Changeset
  alias Phreak.Pod

  @primary_key {:uid, :string, autogenerate: false}
  schema "pods" do
    field :name, :string
    field :status, :string
    field :parent_uid, :string

    timestamps()
  end

  @doc false
  def changeset(pod, attrs) do
    pod
    |> cast(attrs, [:uid, :name])
    |> validate_required([:uid, :name])
  end
end
