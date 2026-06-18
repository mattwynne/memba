# `opened` / `Opened` baseline inventory

Command used:

```sh
grep -RInE 'opened|Opened' web/lib web/test acceptance-tests --exclude-dir=deps --exclude-dir=node_modules || true
```

The Phoenix app lives under `web/`, so `web/lib` and `web/test` are the scoped equivalents of the plan's `lib/` and `test/` paths.

## Production code (`web/lib`)

| Reference | Classification | Notes |
| --- | --- | --- |
| `web/lib/memba_web/controllers/postmark_webhook_controller.ex:45` | Remove | Delete the explicit Postmark `"opened"` rejection branch; unsupported record types should fall through generically. |
| `web/lib/memba_web/member_email_delivery_presentation.ex:145` | Remove | Delete the `"opened" -> "delivered"` presentation mapping. |
| `web/lib/memba/messaging.ex:430` | Remove | Delete member read-model `"opened"` normalization. |
| `web/lib/memba/messaging.ex:439` | Remove | Delete staff read-model `"opened"` normalization. |
| `web/lib/memba/messaging/commands/report_email_delivery_opened.ex:1` | Remove | Delete the deprecated command module. |
| `web/lib/memba/messaging/commands/report_email_delivery_opened.ex:5` | Remove | Goes away with the command module. |
| `web/lib/memba/messaging/projectors/member_email_delivery.ex:17` | Retain-as-shim if required by replay | Keep only if needed for a documented no-op historic-event projector clause. |
| `web/lib/memba/messaging/projectors/member_email_delivery.ex:48` | Retain-as-shim if required by replay | Replace active projection behaviour with a documented no-op only if replay/rebuild requires the clause. |
| `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex:17` | Retain-as-shim if required by replay | Keep only if needed for a documented no-op historic-event projector clause. |
| `web/lib/memba/messaging/projectors/memba_staff_email_delivery.ex:58` | Retain-as-shim if required by replay | Replace active projection behaviour with a documented no-op only if replay/rebuild requires the clause. |
| `web/lib/memba/messaging/events/email_delivery_opened.ex:1` | Retain-as-shim | Keep as the event-store deserialization tombstone with a clear replay-only deprecation comment. |
| `web/lib/memba/messaging/events/email_delivery_opened.ex:3` | Retain-as-shim | Rewrite the module doc/comment to explain replay-only tombstone status. |
| `web/lib/memba/messaging/message.ex:21` | Retain-as-shim | Keep if the aggregate no-op clause references the historic event struct. |
| `web/lib/memba/messaging/message.ex:119` | Retain-as-shim | Reduce aggregate `apply/2` for `EmailDeliveryOpened` to a documented no-op. |
| `web/lib/memba/membership.ex:734` | Unrelated, no status cleanup | This is English prose about invitation links being “reopened”, not the email-delivery status. Leave unless the final grep policy requires wording it around the substring. |

## ExUnit and Cucumber support (`web/test`)

| Reference | Classification | Notes |
| --- | --- | --- |
| `web/test/features/cucumber_configuration_test.exs:18` | Remove/update | Drop or rewrite the guard test so normal tests no longer carry `opened` text outside intentional shim coverage. |
| `web/test/features/cucumber_configuration_test.exs:24` | Remove/update | Same as above. |
| `web/test/features/step_definitions/messaging_steps.exs:12` | Remove | Delete command alias with the command/support cleanup. |
| `web/test/features/step_definitions/messaging_steps.exs:80` | Remove | Delete opened step definition/support plumbing. |
| `web/test/features/step_definitions/messaging_steps.exs:81` | Remove | Delete opened status reporting call. |
| `web/test/features/step_definitions/messaging_steps.exs:110` | Remove | Delete opened status reporting call. |
| `web/test/features/step_definitions/messaging_steps.exs:551` | Remove | Delete special opened-before-delivered support path. |
| `web/test/features/step_definitions/messaging_steps.exs:591` | Remove | Delete opened command construction branch. |
| `web/test/features/step_definitions/messaging_steps.exs:592` | Remove | Goes away with opened command branch. |
| `web/test/features/step_definitions/messaging_steps.exs:672` | Remove | Delete opened label mapping. |
| `web/test/memba_web/controllers/member_message_detail_test.exs:141` | Remove/update | Replace fixture data with a supported status. |
| `web/test/memba_web/controllers/member_message_detail_test.exs:209` | Remove/update | Remove assertion about opened receipt group. |
| `web/test/memba_web/controllers/member_message_detail_test.exs:215` | Remove/update | Remove assertion about opened summary status. |
| `web/test/memba_web/controllers/member_message_detail_test.exs:219` | Remove/update | Remove negative opened assertion if it only exists because of historic opened fixture. |
| `web/test/memba_web/controllers/member_message_detail_test.exs:220` | Remove/update | Same as above. |
| `web/test/memba_web/controllers/postmark_webhook_controller_test.exs:103` | Remove/update | Stop testing supported/explicit opened webhook behaviour. |
| `web/test/memba_web/controllers/postmark_webhook_controller_test.exs:328` | Remove/update | Stop testing special opened unsupported branch. |
| `web/test/memba_web/controllers/postmark_webhook_controller_test.exs:333` | Remove/update | Delete opened payload fixture. |
| `web/test/memba_web/controllers/postmark_webhook_controller_test.exs:334` | Remove/update | Delete opened payload fixture. |
| `web/test/memba_web/controllers/postmark_webhook_controller_test.exs:336` | Remove/update | Delete opened record type mutation. |
| `web/test/memba_web/controllers/postmark_webhook_controller_test.exs:341` | Remove/update | Delete opened webhook assertion. |
| `web/test/memba_web/controllers/postmark_webhook_controller_test.exs:490` | Remove/update | Delete opened Postmark fixture helper branch. |
| `web/test/memba_web/controllers/resend_webhook_controller_test.exs:26` | Remove/update | Stop testing opened Resend payload handling. |
| `web/test/memba_web/controllers/resend_webhook_controller_test.exs:132` | Remove/update | Stop testing opened Resend payload handling. |
| `web/test/memba_web/controllers/resend_webhook_controller_test.exs:271` | Remove/update | Delete opened Resend fixture helper branch. |
| `web/test/memba_web/controllers/resend_webhook_controller_test.exs:275` | Remove/update | Delete opened Resend event type helper branch. |
| `web/test/memba_web/member_dashboard_presentation_test.exs:55` | Remove/update | Replace fixture data with a supported status. |
| `web/test/memba_web/member_email_delivery_presentation_test.exs:29` | Remove | Delete opened presentation assertion. |
| `web/test/memba_web/member_email_delivery_presentation_test.exs:78` | Remove | Delete historic opened visual-normalization test. |
| `web/test/memba_web/member_email_delivery_presentation_test.exs:79` | Remove | Goes away with opened presentation test. |
| `web/test/memba_web/member_email_delivery_presentation_test.exs:80` | Remove | Goes away with opened presentation test. |
| `web/test/memba_web/member_email_delivery_presentation_test.exs:81` | Remove | Goes away with opened presentation test. |
| `web/test/memba_web/member_email_delivery_presentation_test.exs:82` | Remove | Goes away with opened presentation test. |
| `web/test/memba_web/member_email_delivery_presentation_test.exs:104` | Remove | Delete opened-to-delivered folding test. |
| `web/test/memba_web/member_email_delivery_presentation_test.exs:108` | Remove/update | Replace or delete opened fixture. |
| `web/test/memba_web/member_email_delivery_presentation_test.exs:131` | Remove/update | Replace or delete opened fixture. |
| `web/test/memba_web/member_email_delivery_presentation_test.exs:188` | Remove/update | Rename/delete historic opened expectation. |
| `web/test/memba_web/member_email_delivery_presentation_test.exs:195` | Remove/update | Replace or delete opened fixture. |
| `web/test/memba_web/live/member_dashboard_live_test.exs:86` | Remove/update | Replace fixture data with a supported status. |
| `web/test/memba_web/live/member_dashboard_live_test.exs:147` | Remove/update | Remove opened segment assertion. |
| `web/test/memba_web/live/member_dashboard_live_test.exs:326` | Remove/update | Replace fixture data with a supported status. |
| `web/test/memba_web/live/member_dashboard_live_test.exs:377` | Remove/update | Remove opened segment assertion. |
| `web/test/memba_web/live/member_dashboard_live_test.exs:412` | Remove/update | Remove negative opened assertion if it only exists because of opened fixture coverage. |
| `web/test/memba_web/live/member_dashboard_live_test.exs:413` | Remove/update | Same as above. |
| `web/test/memba_web/live/deliveries_live_test.exs:132` | Remove | Delete staff deliveries historic-opened presentation test. |
| `web/test/memba_web/live/deliveries_live_test.exs:144` | Remove | Delete direct opened DB status setup. |
| `web/test/memba_web/live/deliveries_live_test.exs:155` | Remove | Delete opened-row assertion. |
| `web/test/memba_web/live/deliveries_live_test.exs:165` | Remove | Delete opened negative assertion. |
| `web/test/memba_web/live/member_message_live/show_test.exs:130` | Remove/update | Replace fixture data with a supported status. |
| `web/test/memba_web/live/member_message_live/show_test.exs:200` | Remove/update | Remove opened group assertion. |
| `web/test/memba_web/live/member_message_live/show_test.exs:205` | Remove/update | Remove opened summary assertion. |
| `web/test/memba_web/live/member_message_live/show_test.exs:208` | Remove/update | Remove negative opened assertion if it only exists because of opened fixture coverage. |
| `web/test/memba_web/live/member_message_live/show_test.exs:209` | Remove/update | Same as above. |
| `web/test/memba_web/live/member_message_live/show_test.exs:247` | Remove/update | Replace fixture data with a supported status. |
| `web/test/memba_web/live/member_message_live/show_test.exs:269` | Remove/update | Remove opened group toggle assertion. |
| `web/test/memba_web/live/member_message_live/show_test.exs:315` | Remove/update | Replace fixture data with a supported status. |
| `web/test/memba_web/live/member_message_live/show_test.exs:354` | Remove/update | Remove opened summary assertion. |
| `web/test/memba_web/live/member_message_live/show_test.exs:357` | Remove/update | Remove opened group toggle assertion. |
| `web/test/memba/messaging/message_test.exs:14` | Retain/update for shim coverage | Keep only if needed by aggregate no-op replay-shim test; update expectations to unchanged state. |
| `web/test/memba/messaging/message_test.exs:422` | Retain/update for shim coverage | Update from active behaviour to documented no-op behaviour. |
| `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs:11` | Retain/update for replay regression | Keep only as part of intentional historic-event replay-safety coverage. |
| `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs:123` | Retain/update for replay regression | Replace active “maps to delivered” expectation with unaffected/no-op replay coverage. |
| `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs:129` | Retain/update for replay regression | Historic event fixture may remain in the new regression test. |
| `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs:134` | Remove/update | Rename handler/test labels to avoid opened wording unless part of intentional shim coverage. |
| `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs:143` | Remove | Delete read-model `"opened"` normalization test. |
| `web/test/memba/messaging/memba_staff_email_delivery_projection_test.exs:149` | Remove | Delete direct opened row setup. |
| `web/test/memba/messaging/send_message_dispatch_test.exs:9` | Remove | Delete command alias. |
| `web/test/memba/messaging/send_message_dispatch_test.exs:162` | Remove | Delete opened dispatch assertion when command is deleted. |
| `web/test/memba/messaging/status_report_api_test.exs:84` | Remove/update | Drop opened-status API naming from ordinary tests or rewrite without retained status terminology. |
| `web/test/memba/messaging/status_report_api_test.exs:85` | Remove/update | Same as above. |
| `web/test/memba/messaging/status_report_api_test.exs:86` | Remove/update | Same as above. |
| `web/test/memba/messaging/member_email_delivery_projection_test.exs:11` | Retain/update for replay regression | Keep only as part of intentional historic-event replay-safety coverage. |
| `web/test/memba/messaging/member_email_delivery_projection_test.exs:115` | Retain/update for replay regression | Replace active “maps to delivered” expectation with unaffected/no-op replay coverage. |
| `web/test/memba/messaging/member_email_delivery_projection_test.exs:121` | Retain/update for replay regression | Historic event fixture may remain in the new regression test. |
| `web/test/memba/messaging/member_email_delivery_projection_test.exs:126` | Remove/update | Rename handler/test labels to avoid opened wording unless part of intentional shim coverage. |
| `web/test/memba/messaging/member_email_delivery_projection_test.exs:135` | Remove | Delete read-model `"opened"` normalization test. |
| `web/test/memba/messaging/member_email_delivery_projection_test.exs:141` | Remove | Delete direct opened row setup. |

## Acceptance JavaScript support/tests (`acceptance-tests`)

No `.feature` files contain `opened`/`Opened` references in the clean baseline. The remaining references are executable step/support/test plumbing and should be removed or updated; feature files remain locked by the iteration plan.

| Reference | Classification | Notes |
| --- | --- | --- |
| `acceptance-tests/features/support/member_message.js:89` | Remove | Delete opened status/icon support branch. |
| `acceptance-tests/features/support/member_message.js:1873` | Remove | Delete opened event/status mapping branch. |
| `acceptance-tests/features/support/member_message.js:1874` | Remove | Goes away with mapping branch. |
| `acceptance-tests/features/support/member_message.js:1897` | Remove | Delete opened label mapping branch. |
| `acceptance-tests/features/support/member_message.js:1969` | Remove | Delete opened-before-delivered compatibility path. |
| `acceptance-tests/features/support/member_message.js:2004` | Remove/update | Successful delivery report should no longer include opened. |
| `acceptance-tests/features/support/member_message.js:2032` | Remove | Delete opened payload branch. |
| `acceptance-tests/features/step_definitions/member_message_steps.js:365` | Remove | Delete opened status reporting step plumbing. |
| `acceptance-tests/features/step_definitions/member_message_steps.js:368` | Remove | Delete opened step definition. |
| `acceptance-tests/features/step_definitions/member_message_steps.js:369` | Remove | Delete opened status reporting call. |
| `acceptance-tests/test/member_message_steps.test.js:912` | Remove | Delete opened icon assertion. |
| `acceptance-tests/test/member_message_steps.test.js:989` | Remove/update | Delete opened toggle fixture/assertion. |
| `acceptance-tests/test/member_message_steps.test.js:1136` | Remove | Delete opened Postmark payload test. |
| `acceptance-tests/test/member_message_steps.test.js:1197` | Remove | Delete opened event-type mapping assertion. |
| `acceptance-tests/test/member_message_steps.test.js:1421` | Remove | Delete opened-before-delivered test. |
| `acceptance-tests/test/member_message_steps.test.js:1432` | Remove | Goes away with opened-before-delivered test. |
| `acceptance-tests/test/member_message_steps.test.js:1440` | Remove | Goes away with opened-before-delivered test. |
| `acceptance-tests/test/member_message_steps.test.js:1445` | Remove | Goes away with opened-before-delivered test. |
| `acceptance-tests/test/member_message_steps.test.js:1453` | Remove | Goes away with opened-before-delivered test. |
