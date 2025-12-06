defmodule ScoreBreak.Factory do
  @moduledoc """
  Factory module for creating test data.
  """
  alias EctoLtree.LabelTree, as: Ltree
  alias ScoreBreak.Persistence.{Repo, User, Place, UserPlace, Restaurant}

  def build_user(attrs \\ %{}) do
    defaults = %{
      id: Ecto.UUID.generate(),
      first_name: "Test",
      last_name: "User"
    }

    Map.merge(defaults, attrs)
  end

  def create_user(attrs \\ %{}) do
    build_user(attrs)
    |> then(&struct(User, &1))
    |> Repo.insert!()
  end

  def build_place(attrs \\ %{}) do
    id = Map.get(attrs, :id, Ecto.UUID.generate())
    parent_path = Map.get(attrs, :parent_path)
    {:ok, path} = Place.build_path(parent_path, id) |> Ltree.cast()

    defaults = %{
      id: id,
      type: :country,
      name: "Test Place",
      path: path
    }

    attrs_without_parent = Map.drop(attrs, [:parent_path])
    Map.merge(defaults, attrs_without_parent)
  end

  def create_place(attrs \\ %{}) do
    build_place(attrs)
    |> then(&struct(Place, &1))
    |> Repo.insert!()
  end

  @doc """
  Creates a hierarchy of places.
  """
  def create_place_hierarchy(places_spec) when is_list(places_spec) do
    {hierarchy, _paths} =
      Enum.reduce(places_spec, {%{}, %{}}, fn {type, name, parent_name}, {places, paths} ->
        parent_path = if parent_name, do: Map.get(paths, parent_name), else: nil
        place = create_place(%{type: type, name: name, parent_path: parent_path})
        path_str = Place.path_to_string(place)

        {Map.put(places, name, place), Map.put(paths, name, path_str)}
      end)

    hierarchy
  end

  def build_user_place(attrs \\ %{}) do
    defaults = %{
      access: UserPlace.access_bi()
    }

    Map.merge(defaults, attrs)
  end

  def create_user_place(attrs \\ %{}) do
    build_user_place(attrs)
    |> then(&struct(UserPlace, &1))
    |> Repo.insert!()
  end

  def grant_access(user, place, access_type) do
    create_user_place(%{
      user_id: user.id,
      place_id: place.id,
      access: access_type
    })
  end

  def build_restaurant(attrs \\ %{}) do
    defaults = %{
      id: Ecto.UUID.generate(),
      name: "Test Restaurant"
    }

    Map.merge(defaults, attrs)
  end

  def create_restaurant(attrs \\ %{}) do
    build_restaurant(attrs)
    |> then(&struct(Restaurant, &1))
    |> Repo.insert!()
  end

  @doc """
  Returns a map with all places keyed by name.
  """
  def create_standard_hierarchy do
    create_place_hierarchy([
      {:country, "USA", nil},
      {:country, "Canada", nil},
      {:state, "California", "USA"},
      {:state, "New York", "USA"},
      {:state, "Ontario", "Canada"},
      {:state, "Quebec", "Canada"},
      {:county, "LA County", "California"},
      {:city_town, "Los Angeles", "LA County"},
      {:city_town, "NYC", "New York"},
      {:city_town, "Toronto", "Ontario"},
      {:city_town, "Montreal", "Quebec"},
      {:district_ward, "Hollywood", "Los Angeles"},
      {:district_ward, "Manhattan", "NYC"},
      {:neighborhood, "Sunset", "Hollywood"},
      {:neighborhood, "Times Square", "Manhattan"}
    ])
  end
end
