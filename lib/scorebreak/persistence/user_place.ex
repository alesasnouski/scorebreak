defmodule ScoreBreak.Persistence.UserPlace do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id

  @access_single 0
  @access_bi 1
  @access_node 2
  @accesses [@access_single, @access_bi, @access_node]

  def access_single, do: @access_single
  def access_bi, do: @access_bi
  def access_node, do: @access_node

  schema "user_places" do
    field(:access, :integer)

    belongs_to(:user, ScoreBreak.Persistence.User, primary_key: true)
    belongs_to(:place, ScoreBreak.Persistence.Place, primary_key: true)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(user_place, attrs) do
    user_place
    |> cast(attrs, [:user_id, :place_id, :access])
    |> validate_required([:user_id, :place_id, :access])
    |> validate_inclusion(:access, @accesses)
    |> unique_constraint([:user_id, :place_id], name: :user_places_pkey)
  end
end
