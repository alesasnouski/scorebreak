defmodule ScoreBreak.Persistence.Restaurant do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "restaurants" do
    field(:name, :string)
    belongs_to(:place, ScoreBreak.Persistence.Place)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(restaurant, attrs) do
    restaurant
    |> cast(attrs, [:place_id, :name])
    |> validate_required([:place_id, :name])
    |> foreign_key_constraint(:place_id)
  end
end
