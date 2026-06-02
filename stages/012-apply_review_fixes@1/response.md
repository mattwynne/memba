Applied the automatic repair brief for `docs/iterations/017-remove-open-tracking/plan.md`.

## 1. Review issue from gate

### `polish-deprecated-opened-command-moduledoc`
**Status:** Fixed

The deprecated `ReportEmailDeliveryOpened` command moduledoc needed clearer wording about its current lifecycle and dispatch behaviour.

## 2. Changes made

Updated `web/lib/memba/messaging/commands/report_email_delivery_opened.ex` to clarify that:

- open tracking has been removed;
- the struct remains only for historic opened-report command data compatibility;
- the command is no longer routed by `Memba.Messaging.Router`;
- attempting to dispatch it will raise `Commanded.Router.UnregisteredCommandError`.

No product behaviour was changed.

## 3. Files changed by issue

### `polish-deprecated-opened-command-moduledoc`

- `web/lib/memba/messaging/commands/report_email_delivery_opened.ex`

## 4. Tests run

Ran required validation:

```sh
PATH="$PWD/bin:$PATH" dev check
```

Result:

- Passed
- 380 tests, 0 failures

## 5. Remaining gaps or human questions

None.

Note: working tree also shows the existing untracked `.fabro/tmp/` review artifacts from the pipeline. I did not modify or remove them.