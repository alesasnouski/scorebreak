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

  @spec accessible_restaurants(String.t()) :: [%{}]
  def accessible_restaurants(user_id) when is_binary(user_id) do
    user_id
    |> accessible_restaurants_query()
    |> select([restaurant, _rest_place, _user_place, _place], restaurant)
    |> distinct([restaurant, _rest_place, _user_place, _place], restaurant.id)
    |> Repo.all()
  end

  @spec has_restaurant_access?(String.t(), String.t()) :: boolean()
  def has_restaurant_access?(user_id, restaurant_id)
      when is_binary(user_id) and is_binary(restaurant_id) do
    user_id
    |> accessible_restaurants_query()
    |> where([restaurant, _rest_place, _user_place, _place], restaurant.id == ^restaurant_id)
    |> Repo.exists?()
  end

  @spec accessible_restaurants_query(String.t()) :: Ecto.Query.t()
  defp accessible_restaurants_query(user_id) do
    alias ScoreBreak.Persistence.{Place, UserPlace, Restaurant}

    from(r in Restaurant,
      join: rp in Place,
      on: rp.id == r.place_id,
      join: up in UserPlace,
      on: up.user_id == ^user_id,
      join: p in Place,
      on: p.id == up.place_id,
      where: ^access_condition()
    )
  end

  @spec access_condition() :: Ecto.Query.dynamic_expr()
  defp access_condition do
    alias ScoreBreak.Persistence.UserPlace
    # bi - current node and all children
    # single - only children
    # node - siblings with the same parent
    # nlevel(?) = 1     - is special case with `root` place

    dynamic(
      [_r, rp, up, p],
      (up.access == ^UserPlace.access_bi() and
         fragment("? @> ?", p.path, rp.path)) or
        (up.access == ^UserPlace.access_single() and
           fragment("? @> ?", p.path, rp.path) and
           fragment("nlevel(?) + 1 = nlevel(?)", p.path, rp.path)) or
        (up.access == ^UserPlace.access_node() and
           fragment(
             "nlevel(?) = nlevel(?) AND (nlevel(?) = 1 OR subpath(?, 0, nlevel(?) - 1) = subpath(?, 0, nlevel(?) - 1))",
             rp.path,
             p.path,
             rp.path,
             rp.path,
             rp.path,
             p.path,
             p.path
           ))
    )
  end
end
