Goal: Test a short, read-only conversation about the iteration 066 validator finding

## Completed stages
- **evidence**: succeeded
  - Script: `bash .fabro/workflows/iteration-clarification/scripts/read_blocker.sh '01M3HSZ69HTJN82FD03JR94BVV' 'docs/iterations/066-request-group-access/plan.md'`
  - Output:
    ```
    Failed implementation run: 01M3HSZ69HTJN82FD03JR94BVV
    Iteration plan: docs/iterations/066-request-group-access/plan.md
    This is a discussion, not approval to weaken the plan or publish code.
    Latest independent validator verdict:
    Decision: revise
    Task: - [ ] 006 Add and focused-test the signed-in read-only targeted-add route with same-club person/group resolution, current display authority, sign-in return, protected-detail denial, heading focus, selected-person and already-member states, and scanner-safe GET behaviour that performs no membership mutation.
    Reason: Packet 006-8d42dd1-1 is current, matches the first unchecked todo, and has a matching ready_for_review result whose recorded router, targeted-LiveView, and resolver tests passed. The route, sign-in return, focus markup, authoritative target resolution, already-member state, conversation privacy, and mutation-free GET are otherwise implemented. Revision is required because outside-admin display authority still comes from the MemberPermission and active-membership projections through MemberDashboardPresentation; after a committed role revocation or club departure with lagging projections, the route can still render the target and private member list despite the plan and ADR 0024 requiring current Club-owned authority. Add an aggregate-backed current actor check before resolving or rendering target details and focused stale-projection tests proving revoked/departed actors receive generic denial without target or member details. Also use the resolver-returned authoritative group facts in the targeted panel: present_targeted_group_member currently discards target.group and club.html.heex supplies the projected selected_group.name, contrary to the packet requirement that the targeted presentation use only resolver-owned person, membership, group, and participation facts. No test rerun was needed because these gaps are directly evidenced by the current source and are not addressed by the reported successful commands.
    ```


This is a small, read-only test of Fabro's native agent question tool and Slack interviewer with Matt. Do not edit files, run shell commands, start or resume implementation, or approve publication. Use the validator finding from the preceding evidence stage; if it is missing, stop without asking Matt to invent the issue.

Call `request_user_input` to ask ONE clear, specific question about the finding. Address Matt with `<@U0C3C6Y9ZAR>` so Slack notifies him. Explain the current-authority privacy risk in one sentence, then ask whether there is any architectural constraint on repairing it as the approved plan requires. The tool requires `questions` containing `id`, `header`, `question`, and `options`. Use two options: `Repair as planned` and `I have a constraint`. In the question text, explicitly say that Matt can also reply in the message thread (mentioning the Fabro bot) to ask for an example or describe a constraint. This is clarification only, not approval to restart delivery.

Read the tool's answer. If Matt asks for an example or clarification, give the concrete case in the NEXT question via `request_user_input`: Alice's admin role is revoked in the Club aggregate, but a lagging read projection still calls her an admin; she visits the targeted Add page for Bob, which must deny access without showing Bob or the member list. Ask whether that case changes the proposed repair. If Matt gives a substantive constraint, acknowledge it and ask at most one focused follow-up through the same tool. Never assume an option click means approval to publish.

At most three `request_user_input` calls in this test. If the tool fails, is interrupted, or Matt does not answer, report that fact without inventing a decision. End with a concise summary of Matt's actual words, outstanding questions, and the safe next step for a separate operator-controlled recovery. Do not use the final output to claim that iteration 066 is fixed or resumed.
