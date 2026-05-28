# Implementation TODO

- [x] 001 Add the dependencies above with compatible versions; lock them in
- [x] 002 Configure EventStore (dedicated schema) and `commanded_ecto_projections`
- [x] 003 Add `mix` aliases / test helpers so EventStore + projection tables are
- [ ] 004 Add `Memba.Membership.App` and `Memba.Membership.Router`.
- [ ] 005 Add the `Club` aggregate, `CreateClub` command, and `ClubCreated` event,
- [ ] 006 Add the Club projector and a public `Memba.Membership.get_club/1`
- [ ] 007 Add Cucumber configuration that reads `acceptance-tests/features/**/*.feature`
- [ ] 008 Remove conflicting CRUD spike code.
- [ ] 009 Run `devenv shell mix precommit` and fix any issues.
