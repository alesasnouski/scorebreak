defmodule ScoreBreak.Persistence.UserTest do
  use ExUnit.Case, async: true

  alias ScoreBreak.Persistence.{Repo, User, UserPlace}
  import ScoreBreak.Factory

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    places = create_standard_hierarchy()
    {:ok, %{places: places}}
  end

  describe "has_restaurant_access?/2 with `single` access" do
    setup ctx do
      user = create_user(%{first_name: "John", last_name: "Galt"})
      grant_access(user, ctx.places["Los Angeles"], UserPlace.access_single())
      {:ok, Map.put(ctx, :user, user)}
    end

    test "grants access to restaurant in direct child place", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["Hollywood"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == true
    end

    test "denies access to restaurant in the node itself", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["Los Angeles"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == false
    end

    test "denies access to restaurant in grandchild place", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["Sunset"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == false
    end

    test "denies access to restaurant in parent place", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["LA County"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == false
    end

    test "denies access to restaurant in other places", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["Manhattan"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == false
    end
  end

  describe "has_restaurant_access?/2 with `bi` access" do
    setup ctx do
      user = create_user(%{first_name: "Jackie", last_name: "Chan"})
      grant_access(user, ctx.places["Los Angeles"], UserPlace.access_bi())
      {:ok, Map.put(ctx, :user, user)}
    end

    test "grants access to restaurant in the node itself", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["Los Angeles"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == true
    end

    test "grants access to restaurant in direct child place", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["Hollywood"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == true
    end

    test "grants access to restaurant in descendant place", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["Sunset"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == true
    end

    test "denies access to restaurant in parent place", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["LA County"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == false
    end

    test "denies access to restaurant in other places", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["Manhattan"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == false
    end
  end

  describe "has_restaurant_access?/2 with `node` access" do
    setup ctx do
      user = create_user(%{first_name: "Bruce", last_name: "Lee"})
      grant_access(user, ctx.places["California"], UserPlace.access_node())
      {:ok, Map.put(ctx, :user, user)}
    end

    test "grants access to restaurant in the node itself", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["California"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == true
    end

    test "grants access to restaurant in sibling place", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["New York"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == true
    end

    test "denies access to restaurant in child place", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["LA County"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == false
    end

    test "denies access to restaurant in parent place", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["USA"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == false
    end

    test "denies access to restaurant in sibling's descendants", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["NYC"].id})
      assert User.has_restaurant_access?(ctx.user.id, restaurant.id) == false
    end
  end

  describe "has_restaurant_access?/2 edge cases" do
    test "returns false for non-existent restaurant", ctx do
      user = create_user()
      grant_access(user, ctx.places["Los Angeles"], UserPlace.access_bi())
      assert User.has_restaurant_access?(user.id, Ecto.UUID.generate()) == false
    end

    test "returns false for non-existent user", ctx do
      restaurant = create_restaurant(%{place_id: ctx.places["Hollywood"].id})
      assert User.has_restaurant_access?(Ecto.UUID.generate(), restaurant.id) == false
    end
  end

  describe "accessible_restaurants/1" do
    test "returns restaurants in places with bi access", ctx do
      user = create_user()
      grant_access(user, ctx.places["Los Angeles"], UserPlace.access_bi())

      r1 = create_restaurant(%{name: "LA Restaurant", place_id: ctx.places["Los Angeles"].id})

      r2 =
        create_restaurant(%{name: "Hollywood Restaurant", place_id: ctx.places["Hollywood"].id})

      r3 = create_restaurant(%{name: "Sunset Restaurant", place_id: ctx.places["Sunset"].id})

      create_restaurant(%{name: "Manhattan Restaurant", place_id: ctx.places["Manhattan"].id})

      restaurants = User.accessible_restaurants(user.id)
      restaurant_ids = Enum.map(restaurants, & &1.id)

      assert r1.id in restaurant_ids
      assert r2.id in restaurant_ids
      assert r3.id in restaurant_ids
      assert length(restaurants) == 3
    end

    test "returns restaurants in direct children with single access", ctx do
      user = create_user()
      grant_access(user, ctx.places["Los Angeles"], UserPlace.access_single())

      create_restaurant(%{name: "LA Restaurant", place_id: ctx.places["Los Angeles"].id})

      r2 =
        create_restaurant(%{name: "Hollywood Restaurant", place_id: ctx.places["Hollywood"].id})

      create_restaurant(%{name: "Sunset Restaurant", place_id: ctx.places["Sunset"].id})

      restaurants = User.accessible_restaurants(user.id)
      restaurant_ids = Enum.map(restaurants, & &1.id)

      assert r2.id in restaurant_ids
      assert length(restaurants) == 1
    end

    test "returns restaurants in sibling places with node access", ctx do
      user = create_user()
      grant_access(user, ctx.places["California"], UserPlace.access_node())

      r1 =
        create_restaurant(%{name: "California Restaurant", place_id: ctx.places["California"].id})

      r2 = create_restaurant(%{name: "New York Restaurant", place_id: ctx.places["New York"].id})

      create_restaurant(%{name: "LA County Restaurant", place_id: ctx.places["LA County"].id})
      create_restaurant(%{name: "USA Restaurant", place_id: ctx.places["USA"].id})

      restaurants = User.accessible_restaurants(user.id)
      restaurant_ids = Enum.map(restaurants, & &1.id)

      assert r1.id in restaurant_ids
      assert r2.id in restaurant_ids
      assert length(restaurants) == 2
    end

    test "returns empty list for user with no access", _ctx do
      user = create_user()
      restaurants = User.accessible_restaurants(user.id)
      assert restaurants == []
    end

    test "returns empty list for non-existent user", _ctx do
      restaurants = User.accessible_restaurants(Ecto.UUID.generate())
      assert restaurants == []
    end

    test "combines multiple access grants with same access level", ctx do
      user = create_user()
      grant_access(user, ctx.places["Hollywood"], UserPlace.access_bi())
      grant_access(user, ctx.places["Manhattan"], UserPlace.access_bi())

      r1 =
        create_restaurant(%{name: "Hollywood Restaurant", place_id: ctx.places["Hollywood"].id})

      r2 = create_restaurant(%{name: "Sunset Restaurant", place_id: ctx.places["Sunset"].id})

      r3 =
        create_restaurant(%{name: "Manhattan Restaurant", place_id: ctx.places["Manhattan"].id})

      r4 =
        create_restaurant(%{
          name: "Times Square Restaurant",
          place_id: ctx.places["Times Square"].id
        })

      create_restaurant(%{name: "LA Restaurant", place_id: ctx.places["Los Angeles"].id})

      restaurants = User.accessible_restaurants(user.id)
      restaurant_ids = Enum.map(restaurants, & &1.id)

      assert r1.id in restaurant_ids
      assert r2.id in restaurant_ids
      assert r3.id in restaurant_ids
      assert r4.id in restaurant_ids
      assert length(restaurants) == 4
    end

    test "combines multiple access grants with different access levels", ctx do
      user = create_user()
      grant_access(user, ctx.places["Hollywood"], UserPlace.access_bi())
      grant_access(user, ctx.places["Los Angeles"], UserPlace.access_single())
      grant_access(user, ctx.places["California"], UserPlace.access_node())

      r_hollywood =
        create_restaurant(%{name: "Hollywood Restaurant", place_id: ctx.places["Hollywood"].id})

      r_sunset =
        create_restaurant(%{name: "Sunset Restaurant", place_id: ctx.places["Sunset"].id})

      restaurants = User.accessible_restaurants(user.id)
      assert length(restaurants) == 2

      # should NOT be accessible - Los Angeles itself (single doesn't include self)
      create_restaurant(%{name: "LA Restaurant", place_id: ctx.places["Los Angeles"].id})

      restaurants = User.accessible_restaurants(user.id)
      assert length(restaurants) == 2

      r_california =
        create_restaurant(%{name: "California Restaurant", place_id: ctx.places["California"].id})

      r_new_york =
        create_restaurant(%{
          name: "New York State Restaurant",
          place_id: ctx.places["New York"].id
        })

      restaurants = User.accessible_restaurants(user.id)
      assert length(restaurants) == 4

      # should NOT be accessible - parent (USA)
      create_restaurant(%{name: "USA Restaurant", place_id: ctx.places["USA"].id})
      # should NOT be accessible - child of sibling
      create_restaurant(%{name: "NYC Restaurant", place_id: ctx.places["NYC"].id})

      restaurants = User.accessible_restaurants(user.id)
      restaurant_ids = Enum.map(restaurants, & &1.id)

      assert r_hollywood.id in restaurant_ids
      assert r_sunset.id in restaurant_ids

      assert r_california.id in restaurant_ids
      assert r_new_york.id in restaurant_ids

      assert length(restaurants) == 4
    end

    test "does not return duplicates when restaurant matches multiple grants", ctx do
      user = create_user()
      grant_access(user, ctx.places["Los Angeles"], UserPlace.access_bi())
      grant_access(user, ctx.places["Hollywood"], UserPlace.access_bi())

      r1 =
        create_restaurant(%{name: "Hollywood Restaurant", place_id: ctx.places["Hollywood"].id})

      restaurants = User.accessible_restaurants(user.id)

      assert length(restaurants) == 1
      assert hd(restaurants).id == r1.id
    end
  end

  describe "node access at root level (countries)" do
    test "has_restaurant_access? grants access to sibling countries", ctx do
      user = create_user()
      grant_access(user, ctx.places["USA"], UserPlace.access_node())

      r_usa = create_restaurant(%{name: "USA Restaurant", place_id: ctx.places["USA"].id})

      r_canada =
        create_restaurant(%{name: "Canada Restaurant", place_id: ctx.places["Canada"].id})

      assert User.has_restaurant_access?(user.id, r_usa.id) == true
      assert User.has_restaurant_access?(user.id, r_canada.id) == true
    end

    test "accessible_restaurants returns restaurants in sibling countries", ctx do
      user = create_user()
      grant_access(user, ctx.places["USA"], UserPlace.access_node())

      r_usa = create_restaurant(%{name: "USA Restaurant", place_id: ctx.places["USA"].id})

      r_canada =
        create_restaurant(%{name: "Canada Restaurant", place_id: ctx.places["Canada"].id})

      create_restaurant(%{name: "California Restaurant", place_id: ctx.places["California"].id})

      restaurants = User.accessible_restaurants(user.id)
      restaurant_ids = Enum.map(restaurants, & &1.id)

      assert r_usa.id in restaurant_ids
      assert r_canada.id in restaurant_ids
      assert length(restaurants) == 2
    end

    test "node access at root denies access to children's restaurants", ctx do
      user = create_user()
      grant_access(user, ctx.places["USA"], UserPlace.access_node())

      create_restaurant(%{name: "California Restaurant", place_id: ctx.places["California"].id})
      create_restaurant(%{name: "Ontario Restaurant", place_id: ctx.places["Ontario"].id})

      restaurants = User.accessible_restaurants(user.id)
      assert restaurants == []
    end
  end
end
