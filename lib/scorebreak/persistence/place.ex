defmodule ScoreBreak.Persistence.Place do
  @moduledoc false
  use Ecto.Schema

  alias EctoLtree.LabelTree, as: Ltree

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type_country :country
  @type_state :state
  @type_county :county
  @type_city_town :city_town
  @type_district_ward :district_ward
  @type_neighborhood :neighborhood
  @type_block_address :block_address

  @place_types [
    @type_country,
    @type_state,
    @type_county,
    @type_city_town,
    @type_district_ward,
    @type_neighborhood,
    @type_block_address
  ]

  def type_country, do: @type_country
  def type_state, do: @type_state
  def type_county, do: @type_county
  def type_city_town, do: @type_city_town
  def type_district_ward, do: @type_district_ward
  def type_neighborhood, do: @type_neighborhood
  def type_block_address, do: @type_block_address
  def place_types, do: @place_types

  schema "places" do
    field(:type, Ecto.Enum, values: @place_types)
    field(:name, :string)
    field(:path, Ltree)

    has_one(:restaurant, ScoreBreak.Persistence.Restaurant)
    many_to_many(:users, ScoreBreak.Persistence.User, join_through: "user_places")

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(place, attrs) do
    place
    |> cast(attrs, [:type, :name, :path])
    |> validate_required([:name, :path, :type])
  end

  @spec uuid_to_ltree(String.t()) :: String.t()
  def uuid_to_ltree(uuid) when is_binary(uuid) do
    String.replace(uuid, "-", "_")
  end

  @spec build_path(String.t() | nil, String.t()) :: String.t()
  def build_path(nil, id), do: uuid_to_ltree(id)
  def build_path("", id), do: uuid_to_ltree(id)
  def build_path(parent_path, id), do: "#{parent_path}.#{uuid_to_ltree(id)}"

  @spec path_to_string(Ltree.t() | %__MODULE__{}) :: String.t()
  def path_to_string(%__MODULE__{path: path}), do: path_to_string(path)
  def path_to_string(%Ltree{labels: labels}), do: Enum.join(labels, ".")
end
