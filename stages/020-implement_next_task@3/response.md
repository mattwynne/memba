Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `003 Add a minimal club invitation model in the Membership boundary, event-sourced if consistent with nearby Membership aggregates:`

2. **Changes made for this task**
   - Added an event-sourced Membership invitation aggregate:
     - `Memba.Membership.ClubInvitation`
   - Added Membership-owned invitation token helpers, separate from ordinary auth sign-in tokens:
     - `Memba.Membership.InvitationToken`
   - Added invitation commands:
     - `InviteClubMember`
     - `ResendClubMemberInvitation`
     - `AcceptClubMemberInvitation`
   - Added invitation events:
     - `ClubMemberInvited`
     - `ClubMemberInvitationResent`
     - `ClubMemberInvitationAccepted`
   - Registered the new aggregate/commands in `Memba.Membership.Router`.
   - Added a typed caller-generated invitation ID prefix through `Memba.ID` as `:club_invitation`.
   - Added an Ecto projection/read model and projector:
     - `membership_club_invitations`
     - pending/accepted status
     - normalized email
     - invitation token hash
     - resend count
     - accepted person/membership IDs
   - Added migration:
     - `web/priv/repo/migrations/20260608032753_create_membership_club_invitations_projection.exs`
   - Supervised the new projector and included it in event-sourced test reset config.
   - Updated Membership app tests for registered commands and supervised projector.
   - Added focused tests for:
     - invitation token generation/hash validation
     - aggregate invite/resend/accept behavior
     - Commanded dispatch routing
     - projection updates

3. **Focused validation commands run and results**
   - Formatting check:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...`
     - Result: passed.
   - Focused tests:
     - `env -u DEVENV_DOTFILE -u DEVENV_PROFILE -u DEVENV_ROOT -u DEVENV_STATE -u DEVENV_TASKS -u DEVENV_TASK_FILE -u PGDATA -u PGHOST -u PGPORT PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/membership/invitation_token_test.exs test/memba/membership/club_invitation_test.exs test/memba/membership/club_invitation_dispatch_test.exs test/memba/membership/club_invitation_projection_test.exs test/memba/membership/app_test.exs`
     - Result: `18 tests, 0 failures`.
   - Broad quick validation:
     - `env -u DEVENV_DOTFILE -u DEVENV_PROFILE -u DEVENV_ROOT -u DEVENV_STATE -u DEVENV_TASKS -u DEVENV_TASK_FILE -u PGDATA -u PGHOST -u PGPORT PATH="$PWD/bin:$PATH" devenv shell -- dev check --quick`
     - Result: passed — `682 tests, 0 failures`.
   - Note: I used a clean `devenv shell` wrapper because the inherited sandbox `PGHOST` pointed at a stale Postgres socket.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Add a minimal club invitation model in the Membership boundary, event-sourced if consistent with nearby Membership aggregates:`
   - To:
     - `- [x] 003 Add a minimal club invitation model in the Membership boundary, event-sourced if consistent with nearby Membership aggregates:`

5. **Todo splits/additions/reordering**
   - None. No todo lines were split, added, deleted, or reordered.

6. **ADR conformance evidence**
   - Conforms to ADR 0001 by keeping the implementation in the Phoenix/Elixir app.
   - Conforms to ADR 0002 by modelling the new domain workflow with Commanded commands, aggregate, and events.
   - Conforms to ADR 0007 by keeping invitation lifecycle state in the Membership bounded context.
   - Conforms to ADR 0008 by using the existing persistent PostgreSQL EventStore-backed Commanded app.
   - Conforms to ADR 0009 by adding a Commanded Ecto projection/read model.
   - Conforms to ADR 0011 by using caller-generated typed UUID-style invitation IDs.
   - Conforms to ADR 0022 by wiring the projector into the event-sourced test reset/projection infrastructure.