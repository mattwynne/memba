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


This is a read-only test of Fabro's native agent question tool through its Slack interviewer. Do not edit files, run shell commands, start or resume implementation, or approve publication. Use the validator finding from the preceding evidence stage; if missing, stop without asking Matt to diagnose it.

Call `AskUserQuestion` (or `request_user_input` if that is the available name) to ask ONE short question with exactly three visible choices. The tool requires `questions` containing a question, a short header, and options (and possibly an id or multiSelect flag, depending on the tool schema). Use this plain-language explanation: "The Add page might show someone's private member details to a former club admin, because it reads permissions that can be out of date. The approved plan says it must check current permissions first." Ask whether Matt needs an example, knows a reason the planned fix won't work, or understands and has no constraint. The three option labels MUST be, in this order: `Get more context`, `Repair as planned`, `I have a constraint`. Do not imply that choosing any option restarts delivery. Avoid jargon and do not put raw Slack mention markup in the question.

Read the answer returned by the tool. If Matt chooses `Get more context` or asks for an example, give this concrete case in the NEXT tool question: Alice's admin access is removed, but the page still sees an old permissions record saying she's an admin. She opens the Add page for Bob. She must see a generic denial, not Bob's details or the private member list. Ask whether that clarifies the concern. Offer `Repair as planned`, `I have a constraint`, and `Still unclear` as the visible options. If he chooses `Still unclear`, ask one last focused question about what he wants clarified, then stop and report that the issue is unresolved. If he identifies a constraint, ask at most one focused follow-up about it. Do not misrepresent a button click as approval to publish.

At most three question-tool calls total. If the tool fails, is interrupted, or Matt does not answer, report that fact without inventing a decision. End with a concise summary of Matt's actual guidance and unresolved questions. This test cannot fix or resume iteration 066; recovery is a separate operator-controlled step.
