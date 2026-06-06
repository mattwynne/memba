# Implementation TODO

- [x] 001 Inspect current public `/get-started`, homepage links, layouts, auth/current identity assigns, staff navigation, staff club creation LiveView, slug helper modules, membership/person creation APIs, and auth email/token APIs.
- [x] 002 Extract reusable club creation/slug form logic if needed so request conversion and `/admin/clubs` share the same slug generation, validation, and availability behaviour. Prefer reuse over duplication.
- [x] 003 Design the request persistence model:
- [x] 004 Add migration/schema/context functions for creating, listing active, rejecting, and converting requests.
- [x] 005 Implement signed-out `/get-started` form with required-field and email validation.
- [x] 006 Implement signed-in `/get-started` behaviour using the current person’s known name/email as read-only request details.
- [x] 007 Send a new-request notification email to `hello@memba.io` after successful request creation.
- [x] 008 Add staff `/admin/requests` route and LiveView under existing staff authentication.
- [x] 009 Add Requests to the staff navigation without regressing existing Clubs, People, Messages, and Deliveries navigation.
- [x] 010 Build the active requests inbox with clear request details and actions for reject/convert.
- [x] 011 Implement rejection with required internal notes and no requester email.
- [x] 012 Implement conversion preparation with generated/editable slug using the same rules as staff club creation.
- [x] 013 Implement conversion transactionally where practical: create club, create/reuse person, create active membership, mark request converted, and send/wrap welcome email behaviour consistently.
- [ ] 014 Implement welcome email generation with a magic sign-in token and post-auth destination for the new club member home.
- [ ] 015 Add or update tests for public form validation/submission, signed-in prepopulation, notification email, staff authorization, active inbox, rejection, conversion, existing-person reuse, slug validation, welcome email, and preservation of existing club creation/slug behaviour.
- [ ] 016 Add acceptance step support for `request_account.feature` and remove `@wip` once the scenarios pass.
- [ ] 017 Run targeted tests while developing, then run `dev check`.
