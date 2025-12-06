defmodule ScoreBreak.Persistence.UserTest do
  use ExUnit.Case, async: true

  alias ScoreBreak.Persistence.{Repo, User, UserPlace}
  import ScoreBreak.Factory

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    places = create_standard_hierarchy()
    {:ok, %{places: places}}
  end

  describe "tests has_access/2 with `single` access" do
    setup ctx do
      user = create_user(%{first_name: "John", last_name: "Galt"})
      grant_access(user, ctx.places["Los Angeles"], UserPlace.access_single())
      {:ok, Map.put(ctx, :user, user)}
    end

    test "grants access to children only", ctx do
      assert User.has_access(ctx.user.id, ctx.places["Hollywood"].id) == true
    end

    test "denies access to the node", ctx do
      assert User.has_access(ctx.user.id, ctx.places["Los Angeles"].id) == false
    end

    test "denies access to grandchildren", ctx do
      assert User.has_access(ctx.user.id, ctx.places["Sunset"].id) == false
    end

    test "denies access to parent", ctx do
      assert User.has_access(ctx.user.id, ctx.places["LA County"].id) == false
    end

    test "denies access to other places", ctx do
      assert User.has_access(ctx.user.id, ctx.places["Manhattan"].id) == false
    end
  end

  describe "tests has_access/2 with `bi` access" do
    setup ctx do
      user = create_user(%{first_name: "Jackie", last_name: "Chan"})
      grant_access(user, ctx.places["Los Angeles"], UserPlace.access_bi())
      {:ok, Map.put(ctx, :user, user)}
    end

    test "grants access to the node itself", ctx do
      assert User.has_access(ctx.user.id, ctx.places["Los Angeles"].id) == true
    end

    test "grants access to direct children", ctx do
      assert User.has_access(ctx.user.id, ctx.places["Hollywood"].id) == true
    end

    test "grants access to other descendants", ctx do
      assert User.has_access(ctx.user.id, ctx.places["Sunset"].id) == true
    end

    test "denies access to parent", ctx do
      assert User.has_access(ctx.user.id, ctx.places["LA County"].id) == false
    end

    test "denies access to other places", ctx do
      assert User.has_access(ctx.user.id, ctx.places["Manhattan"].id) == false
    end
  end

  describe "tests has_access/2 with `node` access" do
    setup ctx do
      user = create_user(%{first_name: "Bruce", last_name: "Lee"})
      grant_access(user, ctx.places["California"], UserPlace.access_node())
      {:ok, Map.put(ctx, :user, user)}
    end

    test "grants access to the node itself", ctx do
      assert User.has_access(ctx.user.id, ctx.places["California"].id) == true
    end

    test "grants access to siblings at the same level", ctx do
      assert User.has_access(ctx.user.id, ctx.places["New York"].id) == true
    end

    test "denies access to children", ctx do
      assert User.has_access(ctx.user.id, ctx.places["LA County"].id) == false
    end

    test "denies access to parent", ctx do
      assert User.has_access(ctx.user.id, ctx.places["USA"].id) == false
    end

    test "denies access to descendants of siblings", ctx do
      assert User.has_access(ctx.user.id, ctx.places["NYC"].id) == false
    end
  end

  describe "has_access/2 edge cases" do
    test "returns false for non-existent place", ctx do
      user = create_user(%{first_name: "Edge", last_name: "Case"})
      grant_access(user, ctx.places["Los Angeles"], UserPlace.access_bi())
      fake_place_id = Ecto.UUID.generate()
      assert User.has_access(user.id, fake_place_id) == false
    end

    test "returns false for non-existent user", ctx do
      fake_user_id = Ecto.UUID.generate()
      assert User.has_access(fake_user_id, ctx.places["Hollywood"].id) == false
    end
  end

  describe "has_access/2 with access to USA" do
    setup ctx do
      user_single = create_user(%{first_name: "USA", last_name: "Single"})
      user_bi = create_user(%{first_name: "USA", last_name: "Bi"})
      user_node = create_user(%{first_name: "USA", last_name: "Node"})

      grant_access(user_single, ctx.places["USA"], UserPlace.access_single())
      grant_access(user_bi, ctx.places["USA"], UserPlace.access_bi())
      grant_access(user_node, ctx.places["USA"], UserPlace.access_node())

      {:ok, Map.merge(ctx, %{user_single: user_single, user_bi: user_bi, user_node: user_node})}
    end

    test "single: grants access to direct children (states)", ctx do
      assert User.has_access(ctx.user_single.id, ctx.places["California"].id) == true
      assert User.has_access(ctx.user_single.id, ctx.places["New York"].id) == true
    end

    test "single: denies access to USA itself", ctx do
      assert User.has_access(ctx.user_single.id, ctx.places["USA"].id) == false
    end

    test "single: denies access to grandchildren and deeper", ctx do
      assert User.has_access(ctx.user_single.id, ctx.places["LA County"].id) == false
      assert User.has_access(ctx.user_single.id, ctx.places["Los Angeles"].id) == false
    end

    test "bi: grants access to USA itself", ctx do
      assert User.has_access(ctx.user_bi.id, ctx.places["USA"].id) == true
    end

    test "bi: grants access to all descendants", ctx do
      assert User.has_access(ctx.user_bi.id, ctx.places["California"].id) == true
      assert User.has_access(ctx.user_bi.id, ctx.places["New York"].id) == true
      assert User.has_access(ctx.user_bi.id, ctx.places["LA County"].id) == true
      assert User.has_access(ctx.user_bi.id, ctx.places["Los Angeles"].id) == true
      assert User.has_access(ctx.user_bi.id, ctx.places["NYC"].id) == true
      assert User.has_access(ctx.user_bi.id, ctx.places["Hollywood"].id) == true
      assert User.has_access(ctx.user_bi.id, ctx.places["Manhattan"].id) == true
      assert User.has_access(ctx.user_bi.id, ctx.places["Sunset"].id) == true
      assert User.has_access(ctx.user_bi.id, ctx.places["Times Square"].id) == true
    end

    test "node: grants access to USA itself", ctx do
      assert User.has_access(ctx.user_node.id, ctx.places["USA"].id) == true
    end

    test "node: denies access to children (states)", ctx do
      assert User.has_access(ctx.user_node.id, ctx.places["California"].id) == false
      assert User.has_access(ctx.user_node.id, ctx.places["New York"].id) == false
    end

    test "node: grants access to Canada (sibling country)", ctx do
      assert User.has_access(ctx.user_node.id, ctx.places["Canada"].id) == true
    end

    test "node: denies access to Canada's children", ctx do
      assert User.has_access(ctx.user_node.id, ctx.places["Ontario"].id) == false
      assert User.has_access(ctx.user_node.id, ctx.places["Quebec"].id) == false
      assert User.has_access(ctx.user_node.id, ctx.places["Toronto"].id) == false
      assert User.has_access(ctx.user_node.id, ctx.places["Montreal"].id) == false
    end

    test "bi: denies access to Canada", ctx do
      assert User.has_access(ctx.user_bi.id, ctx.places["Canada"].id) == false
      assert User.has_access(ctx.user_bi.id, ctx.places["Ontario"].id) == false
      assert User.has_access(ctx.user_bi.id, ctx.places["Toronto"].id) == false
    end

    test "single: denies access to Canada", ctx do
      assert User.has_access(ctx.user_single.id, ctx.places["Canada"].id) == false
      assert User.has_access(ctx.user_single.id, ctx.places["Ontario"].id) == false
    end
  end
end
