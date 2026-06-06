defmodule MembaWeb.Admin.ClubSlugFormTest do
  use Memba.DataCase, async: true

  alias MembaWeb.Admin.ClubSlugForm

  describe "suggest_params/3" do
    test "generates a default slug from the club name while the slug is blank" do
      assert {%{
                "name" => "Kootenay Mountaineering Club",
                "slug" => "kootenay-mountaineering-club"
              },
              true} =
               ClubSlugForm.suggest_params(
                 %{"name" => "Kootenay Mountaineering Club", "slug" => ""},
                 ["club", "name"],
                 true
               )
    end

    test "preserves a staff-entered slug after override" do
      assert {%{"name" => "Kootenay Mountaineering Club", "slug" => "kmc"}, false} =
               ClubSlugForm.suggest_params(
                 %{"name" => "Kootenay Mountaineering Club", "slug" => "kmc"},
                 ["club", "slug"],
                 true
               )

      assert {%{"name" => "KMC Alpine Club", "slug" => "kmc"}, false} =
               ClubSlugForm.suggest_params(
                 %{"name" => "KMC Alpine Club", "slug" => "kmc"},
                 ["club", "name"],
                 false
               )
    end
  end

  describe "feedback/2" do
    test "rejects invalid staff-entered slugs with shared messaging" do
      assert %{
               status: "invalid",
               valid: false,
               message:
                 "Slug must use lowercase letters, numbers, and hyphens with no leading or trailing hyphen."
             } = ClubSlugForm.feedback(nil, "KMC Club!")

      assert %{
               status: "invalid",
               valid: false,
               message: "Enter a slug."
             } = ClubSlugForm.feedback(nil, "")
    end

    test "reports availability while allowing an edited club to keep its own slug" do
      existing_club =
        insert_membership_club!(
          name: "Kootenay Mountaineering Club",
          slug: "kmc"
        )

      assert %{
               status: "taken",
               valid: false,
               message: "This slug is already used by another club."
             } = ClubSlugForm.feedback(nil, "kmc")

      assert %{
               status: "available",
               valid: true,
               message: "This slug is valid and available."
             } = ClubSlugForm.feedback(existing_club.club_id, "kmc")
    end
  end
end
