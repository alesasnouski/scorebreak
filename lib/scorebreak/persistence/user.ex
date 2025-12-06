defmodule ScoreBreak.Persistence.User do
  @moduledoc false
  use Ecto.Schema
  alias ScoreBreak.Persistence.Repo
  import Ecto.Changeset
  import Ecto.Query

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

  @spec has_access(String.t(), String.t()) :: boolean()
  def has_access(user_id, place_id) when is_binary(user_id) and is_binary(place_id) do
    alias ScoreBreak.Persistence.Place

    case Repo.one(from(p in Place, where: p.id == ^place_id)) do
      nil ->
        false

      %Place{path: check_path} ->
        check_path_str = to_string(check_path)
        place_permission_exists?(user_id, check_path_str)
    end
  end

  @spec place_permission_exists?(String.t(), String.t()) :: boolean()
  defp place_permission_exists?(user_id, check_path) do
    alias ScoreBreak.Persistence.{Place, UserPlace}
    # bi - current node and all children
    # single - only children
    # node - siblings with the same parent

    from(up in UserPlace,
      join: p in Place,
      on: p.id == up.place_id,
      where:
        up.user_id == ^user_id and
          ((up.access == ^UserPlace.access_bi() and
              fragment("? @> ?", p.path, ^check_path)) or
             (up.access == ^UserPlace.access_single() and
                fragment("? @> ?", p.path, ^check_path) and
                fragment("nlevel(?) + 1 = nlevel(?)", p.path, ^check_path)) or
             (up.access == ^UserPlace.access_node() and
                fragment(
                  "nlevel(?) = nlevel(?) AND subpath(?, 0, nlevel(?) - 1) = subpath(?, 0, nlevel(?) - 1)",
                  ^check_path,
                  p.path,
                  ^check_path,
                  ^check_path,
                  p.path,
                  p.path
                )))
    )
    |> Repo.exists?()
  end
end
