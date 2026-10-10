# 068 conflict interaction: approved behaviour and design handoff

Status: external handoff superseded by Matt's explicit direction to design here in BB using HTML
mock-ups and the base design language/components. Behaviour/text mock-up approved; local visual
proposal awaiting review: [name-conflict-mockup.html](name-conflict-mockup.html).

## Approved interaction

An untouched name form follows current saved data automatically. A dirty form retains its draft.
After a conflicting Save, preserve the draft and display the newer value with generic wording:

```text
Your name
[ Alice Brown                         ]

Changed elsewhere to “Alice Jones”.
Saving your edit will replace that value.

[ Save my value ]  [ Use latest ]
```

- Save my value explicitly confirms replacing the shown value. If that value changes again before
  confirmation, show the updated conflict and require confirmation again. No unconditional overwrite.
- Use latest adopts the latest saved value and discards the draft without writing.
- No proactive-warning machinery, merge interface, silent last-write-wins, or automatic discard.
- The interaction should be simple and reusable across fields/forms. This iteration does not migrate
  all forms or introduce a general collaborative-editing framework.
- Earlier Cancel/re-edit-only and discard-with-toast proposals are superseded.

## Historical handoff — no longer a required external step

The following records the earlier proposal, not the current required workflow. Matt subsequently
chose local HTML design in this thread. Review that local proposal before ready publication; do not
require a Claude Code transfer or claim a DesignSync push occurred.

### Earlier handoff proposal

Pi cannot inspect or publish the live design system through DesignSync. The checked-in
`design-system/templates/account-settings.html` has display/edit/validation-error cards but lacks
this two-action conflict state. The UX skill requires a Claude Code handoff rather than pretending
that the existing error card fully covers changed actions.

Restart prompt for a Claude Code design session:

> Finish design coverage only for iteration 068's approved conflict interaction. Inspect the live
> Account settings design with DesignSync and the checked-in account-settings template. Add the
> approved state above using the existing name form and inline feedback styling. Keep generic
> wording, preserve draft text, show the current value, and distinguish explicit replacement from
> adopting latest. Cover long values, narrow screens, keyboard/focus handling and accessible
> conflict announcements. Do not add photos, staff refresh, proactive warnings, merge UI or an
> app-wide form migration. Render-verify and sync the design; return exact design paths and review
> evidence. Material design choices remain Matt's. No application implementation or delivery launch.

Parent owns the final whole-plan ensemble, not this design task. Required material-design review
remains separate. Once design coverage returns, resume formulation/model review and planning checks;
do not label this handoff or the plan ready before those gates are satisfied.
