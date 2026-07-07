# Implementation TODO

- [x] 001 Add a member-scoped route `live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show` in `web/lib/memba_web/router.ex`, in the same authenticated member scope as the message Show route.
- [x] 002 Create `MemberMessageDeliveryLive.Show` that loads the target message and its receipt model via `Messaging.list_member_email_deliverys/1 |> MemberEmailDeliveryPresentation.present_receipts/1`, scoped to the member's active clubs (reuse the `member_message_detail` load pattern and authz).
- [x] 003 Build the delivery page template per `delivery-details.html`: header (subject / sender / `inserted_at`), summary bar + legend, grouped recipients (problems expanded, delivered collapsed).
- [x] 004 Show each recipient's bounce reason for the "didn't go through" group, from the existing receipt presentation fields; keep the delivered group collapsed with a count.
- [x] 005 Port the delivery-details CSS (`delivery-summary`, `delivery-bar`, `delivery-legend`, `delivery-group`, `recipient`, `deliv-*` tints) from `design-system/` into `web/assets/css/app.css`, names 1:1 with the mirror.
- [ ] 006 Add a **Back to conversation** link on the delivery page returning to the message's conversation.
- [ ] 007 Add a per-message **⋮ menu** to `conversation_entry_card` (`page_html.ex`) with a Delivery details item linking to `/messages/#{message_id}/delivery`.
- [ ] 008 Remove the inline `#member-receipt-summary` section and the "Members by delivery status" grouped section from `message.html.heex`.
- [ ] 009 Remove the "sent to N members" delivery meta line from the conversation subject header.
- [ ] 010 Add tests: the delivery route renders the per-recipient breakdown for a message; it enforces the same authz as the conversation; the conversation kebab links to it; the conversation no longer renders the inline delivery sections.
- [ ] 011 Run `./bin/dev gallery-walk` and compare the delivery page to `delivery-details.html` and the conversation to `member-conversation.html`.
- [ ] 012 Run `dev check` and confirm it is green (no feature-file changes).
