defmodule MembaWeb.MemberMessageLive.ShowTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders a member message detail LiveView shell in the club site layout", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, MembaWeb.MemberMessageLive.Show)

    assert has_element?(view, "#club-site-layout[data-surface='club-site']")
    assert has_element?(view, "#member-message-detail[data-live-view='member-message-detail']")
  end
end
