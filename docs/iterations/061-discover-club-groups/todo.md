# Implementation TODO

- [x] 001 Separate discovery from participation in the Membership public query API.
- [x] 002 Add a club-scoped discovery summary for an authenticated active club member.
- [x] 003 Preserve `list_active_groups_for_member/2` as the actual-membership API: Messaging uses it for access, so broadening it would expose conversations.
- [x] 004 Update `MemberDashboardPresentation` to resolve group identity within the authorised club, then load only the permitted surface.
- [ ] 005 Explicitly distinguish ordinary non-member, outside admin and participating member.
- [ ] 006 Extend the existing stateless tabs/frame/list composition in `page_html/club.html.heex` and `member_dashboard_group_tabs.ex`.
- [ ] 007 Keep one contextual action slot, correct tab/panel ARIA and keyboard behaviour.
- [ ] 008 Preserve selected-group routing and remembered selection through `MemberDashboardLive` and its existing browser hook.
- [ ] 009 Refresh discovery/access state on relevant read-model changes; reject direct actions after access loss.
- [ ] 010 Keep conversation access in public Membership/Messaging APIs, not projection joins in the web layer.
- [ ] 011 Implement the tagged domain/browser examples and focused presentation, component and routed LiveView regressions. Verify no disclosure on guessed URLs, cross-club IDs or stale browser state; run `dev check` on the exact delivered state.
