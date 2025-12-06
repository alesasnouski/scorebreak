defmodule ScoreBreak.Persistence.User do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field(:first_name, :string)
    field(:last_name, :string)

    many_to_many(:places, ScoreBreak.Persistence.Place, join_through: "user_places")

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name])
    |> validate_required([])
  end
end
