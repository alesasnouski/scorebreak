# mix run priv/repo/seeds.exs
alias EctoLtree.LabelTree, as: Ltree
alias ScoreBreak.Persistence.{Repo, User, Place, UserPlace, Restaurant}

john = %User{first_name: "John", last_name: "Doe"} |> Repo.insert!()
jane = %User{first_name: "Jane", last_name: "Smith"} |> Repo.insert!()
bob = %User{first_name: "Bob", last_name: "Johnson"} |> Repo.insert!()


create_place = fn type, name, parent_path ->
  id = Ecto.UUID.generate()

  {:ok, path} = Place.build_path(parent_path, id) |> Ltree.cast()
  %Place{id: id, type: type, name: name, path: path}
  |> Repo.insert!()
end

# Country
usa = create_place.(:country, "United States", nil)
usa_path = Place.path_to_string(usa)

# States
california = create_place.(:state, "California", usa_path)
california_path = Place.path_to_string(california)

new_york = create_place.(:state, "New York", usa_path)
new_york_path = Place.path_to_string(new_york)

# County
la_county = create_place.(:county, "Los Angeles County", california_path)
la_county_path = Place.path_to_string(la_county)

# Cities
los_angeles = create_place.(:city_town, "Los Angeles", la_county_path)
los_angeles_path = Place.path_to_string(los_angeles)

nyc = create_place.(:city_town, "New York City", new_york_path)
nyc_path = Place.path_to_string(nyc)

# Districts
hollywood = create_place.(:district_ward, "Hollywood", los_angeles_path)
hollywood_path = Place.path_to_string(hollywood)

manhattan = create_place.(:district_ward, "Manhattan", nyc_path)
manhattan_path = Place.path_to_string(manhattan)

# Neighborhoods
sunset = create_place.(:neighborhood, "Sunset Boulevard", hollywood_path)
sunset_path = Place.path_to_string(sunset)

times_square = create_place.(:neighborhood, "Times Square", manhattan_path)
times_square_path = Place.path_to_string(times_square)

# Blocks
block_6801 = create_place.(:block_address, "6801 Hollywood Blvd", sunset_path)
block_1515 = create_place.(:block_address, "1515 Broadway", times_square_path)

# John has node access to California (can see siblings at same level)
%UserPlace{user_id: john.id, place_id: california.id, access: UserPlace.access_node()}
|> Repo.insert!()

# Jane has single access to Hollywood (only direct children)
%UserPlace{user_id: jane.id, place_id: hollywood.id, access: UserPlace.access_single()}
|> Repo.insert!()

# Jane has bi access to Manhattan (current node + all descendants)
%UserPlace{user_id: jane.id, place_id: manhattan.id, access: UserPlace.access_bi()}
|> Repo.insert!()

# Bob has bi access to entire USA
%UserPlace{user_id: bob.id, place_id: usa.id, access: UserPlace.access_bi()}
|> Repo.insert!()

%Restaurant{name: "Sunset Grill", place_id: block_6801.id} |> Repo.insert!()
%Restaurant{name: "Broadway Bistro", place_id: block_1515.id} |> Repo.insert!()
%Restaurant{name: "Hollywood Diner", place_id: hollywood.id} |> Repo.insert!()
%Restaurant{name: "Times Square Pizza", place_id: times_square.id} |> Repo.insert!()
