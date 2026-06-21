Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KVP1BKZYMH8J6J02XQTP4S89
Pipeline progress: 5 of 27 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/041-reply-by-email-threading/plan.md'
if [ ! -f "$PLAN_PATH" ]; then
  echo "Iteration plan not found: $PLAN_PATH" >&2
  exit 1
fi
printf 'PLAN_PATH=%s\n\n' "$PLAN_PATH"
line_count=0
while IFS= read -r line && [ "$line_count" -lt 320 ]; do
  printf '%s\n' "$line"
  line_count=$((line_count + 1))
done < "$PLAN_PATH"`
- Output:
  ```
  (100 lines omitted)
  - The `@iteration-041` scenarios pass with temporary tags removed/narrowed; existing scenarios stay green.
  - `dev check` passes.
  
  ## Open Business Decisions
  
  None known.
  
  Confirmed (from 039/040): membership required; auto-follow on reply; followers receive replies. Confirmed for 041: no visible conversation token/address id; reply-vs-new is decided by Memba-recognized email headers; no recognized same-club reply header means a new club-wide message; unsafe mail is rejected with existing rejection behaviour.
  
  ## Implementation Plan
  
  1. Add outbound message-id support: generate Memba-controlled RFC `Message-ID` values for outbound club/reply emails and persist a mapping from message id to Memba message/conversation/club. Likely touchpoints: `Memba.Messaging.MemberMessageEmail`, provider adapters, `EmailDeliveryRequest`, and a projection/table or fields that make lookup deterministic.
  2. Set reply email headers: club/reply emails should route normal replies to `<club-slug>@clubs.memba.io`; reply notification emails should set `In-Reply-To` / `References` so email clients thread and Memba can recognize the conversation on inbound.
  3. Extend inbound parsing: parse `In-Reply-To` and all `References` message ids in Postmark/Resend provider-neutral inbound structs. Likely touchpoints: `MembaWeb.PostmarkInboundEmailParser`, `MembaWeb.ResendInboundEmailParser`, and `Memba.Messaging.InboundEmail`.
  4. Extend inbound routing: before creating a new club-wide message, attempt a same-club header match; when found, post via the 039 reply path, apply current-member authorization, auto-follow the replier, fan out to followers, and apply basic quoted-history stripping.
  5. Preserve and test fallback behaviour: no same-club header match remains the existing club-wide inbound message path; non-members, ambiguous senders, unsupported bodies/attachments, unknown clubs, and malformed provider payloads keep using existing rejection behaviour.
  6. Make the `@iteration-041` scenarios executable; remove/narrow `@todo-*`.
  7. Run `dev check`.
  
  ## Open Technical Decisions
  
  None that require product decisions before implementation.
  
  Implementation choices left to the implementer, with constraints:
  
  - The message-id mapping may live on an outbound-message/read model, delivery record, or dedicated projection/table, provided lookup from an inbound RFC message id to the correct Memba message/conversation/club is deterministic and survives replay/deploy.
  - It is acceptable for 041 to support email replies only to Memba emails sent after this change. Backfilling older outbound emails that lacked persisted Memba `Message-ID` mappings is out of scope.
  - Sender authenticity reuses the existing inbound provider trust model: match `From` to Memba’s known primary/alternate person email addresses and require exactly one current member in the addressed club. No/ambiguous/non-current matches are rejected.
  - Header parsing should tolerate angle brackets, whitespace, folded/multiple values, and common comma/space-separated `References` formats.
  
  ## New Capability
  
  The conversation closes the loop: a member can reply from wherever they read the message — in Memba or straight from their inbox — and it lands in the same tracked conversation and reaches the people following it. The club address remains simple and email-native: the same address starts new messages and receives replies, while standard email headers decide which is which.
  
  ## Validation Plan
  
  - Email generation tests: outbound club/reply emails include persisted Memba `Message-ID`; reply notification emails route replies to `<club-slug>@clubs.memba.io`; `In-Reply-To` / `References` are set for conversation replies.
  - Header parsing/lookup tests: `In-Reply-To` and `References` resolve to the correct same-club conversation; missing, malformed, unknown, and different-club message ids do not create cross-club replies.
  - Inbound tests: matched member reply posts into the conversation and fans out (040); sender is attributed; replier auto-follows; non-member/ambiguous sender rejected; no header match still creates a new club-wide message; basic quote stripping stores usable new text.
  - Provider parser tests for Postmark/Resend inbound payload headers.
  - `@iteration-041` acceptance scenarios green; existing 039/040 reply/follower scenarios and 019/020 inbound club-message scenarios green.
  - Full `dev check`.
  
  ## Risks / Follow-ups
  
  - **Inbound matching is the core risk.** Header-only routing matches Topicbox-style behaviour and keeps addresses simple, but relies on mail clients preserving `In-Reply-To` / `References`. If a client strips headers, Memba treats the mail as a new club-wide message.
  - Older outbound Memba emails without persisted `Message-ID` mappings cannot be routed as replies by this mechanism.
  - Quoted-history bloat in stored replies; basic stripping now, better parsing as a follow-up.
  - Authenticity/spoofing of inbound `From`; lean on the existing inbound pipeline’s trust model and note stronger SPF/DKIM/DMARC hardening as follow-up.
  - Depends on 039 (conversation/reply) and 040 (follower fan-out + reply email shape); sequenced last for that reason.
  ```

## Stage: preflight_sandbox
- Status: succeeded
- Handler: command
- Script: `set -eu
if [ ! -x bin/dev ]; then
  echo "Missing or non-executable bin/dev" >&2
  exit 1
fi
status=$(git status --short)
if [ -n "$status" ]; then
  echo 'Iteration review requires a clean working tree before review starts.' >&2
  printf '%s\n' "$status" >&2
  exit 1
fi
rm -rf .fabro/tmp
mkdir -p .fabro/tmp
git rev-parse HEAD > .fabro/tmp/review-start-sha.txt
echo "Review start SHA: $(cat .fabro/tmp/review-start-sha.txt)"
PATH="$PWD/bin:$PATH" dev sandbox-check`
- Output:
  ```
  (267 lines omitted)
  ==> commanded
  Compiling 69 files (.ex)
  Generated commanded app
  ==> commanded_eventstore_adapter
  Compiling 2 files (.ex)
  Generated commanded_eventstore_adapter app
  ==> commanded_ecto_projections
  Compiling 1 file (.ex)
  Generated commanded_ecto_projections app
  ==> tailwind
  Compiling 3 files (.ex)
  Generated tailwind app
  ==> elixir_make
  Compiling 8 files (.ex)
  Generated elixir_make app
  ==> cc_precompiler
  Compiling 3 files (.ex)
  Generated cc_precompiler app
  ==> lazy_html
  Downloading precompiled NIF to /tmp/cache/elixir_make/lazy_html-nif-2.16-x86_64-linux-gnu-0.1.11.tar.gz
  Compiling 3 files (.ex)
  Generated lazy_html app
  ==> websock
  Compiling 1 file (.ex)
  Generated websock app
  ==> bandit
  Compiling 54 files (.ex)
  Generated bandit app
  ==> swoosh
  Compiling 59 files (.ex)
  Generated swoosh app
  ==> websock_adapter
  Compiling 4 files (.ex)
  Generated websock_adapter app
  ==> phoenix
  Compiling 74 files (.ex)
  Generated phoenix app
  ==> phoenix_live_view
  Compiling 49 files (.ex)
  Generated phoenix_live_view app
  ==> phoenix_live_dashboard
  Compiling 36 files (.ex)
  Generated phoenix_live_dashboard app
  ==> phoenix_test
  Compiling 31 files (.ex)
  Generated phoenix_test app
  ==> phoenix_ecto
  Compiling 7 files (.ex)
  Generated phoenix_ecto app
  Sandbox runtime check passed.
  ```

## Stage: dev_check
- Status: succeeded
- Handler: command
- Script: `PATH="$PWD/bin:$PATH" dev ci`
- Output:
  ```
  (1362 lines omitted)
  
    Rule: Staff-edited slugs must already be address-safe
  
      Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-06-21T21:38:22.539Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-06-21T21:38:22.566Z] scenario reset app state: Staff enter an invalid slug
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-21T21:38:23.784Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1182ms
        Given Kootenay Mountaineering Club is a club
        When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
        Then Memba should reject the club slug as invalid
        And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-06-21T21:38:25.153Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-06-21T21:38:25.161Z] scenario finish: Staff enter an invalid slug status=PASSED duration=2623ms
  
    Rule: A slug can belong to only one club
  
      Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-06-21T21:38:25.162Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-06-21T21:38:25.194Z] scenario reset app state: Staff enter a slug that another club already uses
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-21T21:38:26.376Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1114ms
        Given Kootenay Mountaineering Club has the slug "kmc"
        And Nelson Paddling Club is a club
        When Pat tries to change Nelson Paddling Club's slug to "kmc"
        Then Memba should reject the club slug as already taken
        And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-06-21T21:38:28.155Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-06-21T21:38:28.165Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=3003ms
  
    Rule: A club slug routes public visitors to that club's public page
  
      @not-domain
      Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-06-21T21:38:28.165Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-06-21T21:38:28.197Z] scenario reset app state: Robin opens an unknown club subdomain
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-21T21:38:29.390Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1122ms
        When Robin opens "unknown.clubs.memba.io"
        Then Robin should see a not found page
  [acceptance 2026-06-21T21:38:29.463Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-06-21T21:38:29.467Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1302ms
  
  [acceptance 2026-06-21T21:38:29.468Z] AfterAll: closing shared browser
  [acceptance 2026-06-21T21:38:29.494Z] AfterAll: closed shared browser
  [acceptance 2026-06-21T21:38:29.494Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-06-21T21:38:29.495Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  82 scenarios (82 passed)
  493 steps (493 passed)
  4m20.331s (executing steps: 4m07.404s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh '108b67402cf434f05fa988a72bd67992052b623c'`
- Output:
  ```
  (6987 lines omitted)
      ]
  
      for {field, remove_field} <- required_field_removals do
        assert {:error, {:missing_required_attribute, ^field}} =
                 valid_payload()
                 |> remove_field.()
                 |> ResendInboundEmailParser.parse()
      end
    end
  
    test "rejects invalid required field shapes" do
      payload =
        valid_payload()
        |> put_in(["data", "to"], [])
  
      assert {:error, :invalid_recipient_addresses} = ResendInboundEmailParser.parse(payload)
    end
  
    test "rejects malformed optional inbound email fields" do
      malformed_payloads = [
        {:invalid_provider_message_id, put_in(valid_payload(), ["data", "email_id"], %{})},
        {:invalid_from_address, put_in(valid_payload(), ["data", "from"], "Alice Example")},
        {:invalid_text_body, put_in(valid_payload(), ["data", "text"], %{"body" => "Hi"})},
        {:invalid_html_body, put_in(valid_payload(), ["data", "html"], %{"body" => "<p>Hi</p>"})},
        {:invalid_attachments,
         put_in(valid_payload(), ["data", "attachments"], [
           %{"filename" => "route.gpx", "size" => -1}
         ])}
      ]
  
      for {reason, payload} <- malformed_payloads do
        assert {:error, ^reason} = ResendInboundEmailParser.parse(payload)
      end
    end
  
    defp valid_payload do
      %{
        "id" => "evt_123",
        "type" => "email.received",
        "data" => %{
          "id" => "email_fallback_id",
          "email_id" => "email_123",
          "from" => "alice@example.com",
          "to" => ["kmc@clubs.memba.io"],
          "subject" => "Trip planning night",
          "text" => "Bring route ideas."
        }
      }
    end
  end
  ```

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 6.1k in / 7.9k out
- Response:
  > # Iteration 041 Implementation Review
  > 
  > ## Decision: ACCEPT
  > 
  > ## Confidence: High
  > 
  > ## ADR Conformance: PASS
  > 
  > The implementation correctly follows the ADR decisions cited in the plan:
  > 
  > - **ADR-0048 (Topicbox-style routing)**: Uses Message-ID/In-Reply-To/References headers for routing, falls back to new club message when no match found, restricts matching to same club to prevent cross-club reply routing
  > - **ADR-0050 (Optimistic query/command bridging)**: Auto-follow pattern correctly uses optimistic query (`following?`) before command (`follow_conversation`) after the primary reply command succeeds
  > 
  > The implementation also adheres to the project's domain-driven design, CQRS, event sourcing, and responsibility-driven design patterns as documented in the reference docs.
  > 
  > ## ADR Violations
  > 
  > None.
  > 
  > ## Blocking Issues
  > 
  > None.
  > 
  > The implementation:
  > - Passes all automated tests including acceptance scenarios
  > - Generates and persists RFC-compliant Message-ID values
  > - Sets appropriate reply headers (Reply-To, In-Reply-To, References)
  > - Parses inbound headers robustly (handles angle brackets, whitespace, folded values)
  > - Routes matched replies to conversations vs new messages
  > - Preserves existing rejection/fallback behavior
  > - Covers critical paths, edge cases, and error states in tests
  > 
  > ## Bounded-Safe Fixes
  > 
  > 1. **Extract conversation lookup to Messaging context**
  >    - Currently `InboundRouter.match_conversation_by_headers/1` directly queries `DeliveryReceipt` via `Repo`
  >    - Move to `Messaging.find_conversation_by_message_ids(club_id, message_ids)` for better separation and testability
  >    - Reduces web-boundary coupling to read-model schema details
  > 
  > 2. **Deduplicate header parsing logic**
  >    - `PostmarkInboundEmailParser` and `ResendInboundEmailParser` have nearly identical `extract_references/1` and `parse_message_ids/1` functions
  >    - Extract to shared `MembaWeb.Email.HeaderParser` module
  >    - Both parsers call the shared implementation
  > 
  > 3. **Add documentation comments**
  >    - `InboundRouter` module lacks `@moduledoc` explaining the routing strategy
  >    - Key functions like `match_conversation_by_headers/1`, `route_to_conversation/2` lack `@doc` comments
  >    - Add brief explanations of header-based routing, same-club restriction, and fallback logic
  > 
  > ## Judgement-Worthy Non-Blocking Code-Health Findings
  > 
  > 1. **Message-ID format exposes internal IDs**
  >    - **Files**: `lib/memba/messaging/member_message_email.ex`
  >    - **Smell**: Format `<delivery_receipt_id.club_slug@memba.io>` exposes database primary keys in external email headers
  >    - **Why judgement**: If delivery receipt IDs are sequential, this leaks information about volume/activity. Privacy/security consideration for external-facing identifiers. Alternative: use UUID or hash-based format.
  >    - **Impact**: Low for private clubs; potential privacy leak for public use cases
  > 
  > 2. **Basic quote stripping may degrade UX**
  >    - **Files**: `lib/memba_web/email/inbound_router.ex` (`extract_reply_body/1`)
  >    - **Smell**: Simple heuristics (`starts_with?(">")`, `contains?("wrote:")`) may fail on email clients with different quote formats (HTML-only quotes, localized "On ... wrote", etc.)
  >    - **Why judgement**: Plan explicitly defers better parsing as follow-up. Current approach stores potentially bloated quoted history. May need investment before broader rollout if UX suffers.
  >    - **Impact**: Degrades message readability; users see quoted history in conversation threads
  > 
  > 3. **No rate limiting for email replies**
  >    - **Files**: `lib/memba_web/email/inbound_router.ex`
  >    - **Smell**: Accepts all authenticated member replies without per-user rate limits or spam detection
  >    - **Why judgement**: Could enable conversation flooding by malicious or compromised members. Needs product/security decision on acceptable limits and monitoring strategy.
  >    - **Impact**: Potential abuse vector; may need proactive vs reactive mitigation
  > 
  > 4. **Conversation matching orders by `inserted_at DESC, limit: 1`**
  >    - **Files**: `lib/memba_web/email/inbound_router.ex` (`match_conversation_by_headers/1`)
  >    - **Smell**: If multiple delivery receipts share the same message_id (e.g., due to bug, resend, or concurrent fan-out), this returns the newest receipt. May not always be the correct conversation.
  >    - **Why judgement**: Unclear if message_id is guaranteed unique per club or globally. If duplicates are possible, should we validate/prevent them or handle gracefully?
  >    - **Impact**: Low if message_ids are unique; could cause mis-routing if duplicates exist
  > 
  > ## Suggested Fixes
  > 
  > For **bounded-safe fixes**, concrete changes:
  > 
  > 1. Add `Messaging.find_conversation_by_message_ids/2`:
  >    ```elixir
  >    # In lib/memba/messaging.ex
  >    def find_conversation_by_message_ids(club_id, message_ids) when is_list(message_ids) do
  >      query =
  >        from dr in DeliveryReceipt,
  >        where: dr.message_id in ^message_ids,
  >        where: dr.club_id == ^club_id,
  >        where: not is_nil(dr.conversation_id),
  >        order_by: [desc: dr.inserted_at],
  >        limit: 1,
  >        select: dr.conversation_id
  > 
  >      case Repo.one(query) do
  >        nil -> {:error, :no_match}
  >        conv_id -> {:ok, get_conversation!(conv_id)}
  >      end
  >    end
  >    ```
  >    
  >    Update `InboundRouter.match_conversation_by_headers/1` to call this function.
  > 
  > 2. Create `MembaWeb.Email.HeaderParser`:
  >    ```elixir
  >    defmodule MembaWeb.Email.HeaderParser do
  >      @moduledoc """
  >      Shared utilities for parsing RFC 2822 email headers.
  >      """
  > 
  >      def parse_message_ids(value) when is_binary(value) do
  >        value
  >        |> String.split(~r/[\s,]+/)
  >        |> Enum.map(&String.trim/1)
  >        |> Enum.reject(&(&1 == ""))
  >        |> Enum.map(&remove_angle_brackets/1)
  >      end
  > 
  >      defp remove_angle_brackets(id) do
  >        id
  >        |> String.trim_leading("<")
  >        |> String.trim_trailing(">")
  >      end
  >    end
  >    ```
  >    
  >    Update both parsers to `alias MembaWeb.Email.HeaderParser` and call `HeaderParser.parse_message_ids/1`.
  > 
  > 3. Add module and function docs:
  >    ```elixir
  >    defmodule MembaWeb.Email.InboundRouter do
  >      @moduledoc """
  >      Routes inbound club emails to conversations or new club-wide messages.
  > 
  >      Uses Message-ID/In-Reply-To/References headers to match email replies
  >      to existing conversations (Topicbox-style routing per ADR-0048).
  >      Falls back to creating new club-wide messages when no conversation match.
  >      """
  > 
  >      # ... existing code ...
  > 
  >      @doc """
  >      Attempts to match an inbound email to an existing conversation using
  >      In-Reply-To and References headers. Returns the conversation if a
  >      same-club match is found; otherwise returns an error.
  >      """
  >      defp match_conversation_by_headers(email) do
  >        # ...
  >      end
  >    end
  >    ```
  > 
  > For **judgement-worthy findings**, defer to human decision or future iteration:
  > - #1: Consider UUID-based message_id format in follow-up privacy review
  > - #2: Monitor quote-stripping UX; invest in better parsing if needed pre-launch
  > - #3: Add rate limiting when abuse monitoring indicates necessity
  > - #4: Add unique index on message_id if not already present; validate uniqueness invariant
  > 
  > ## Validation Notes
  > 
  > - **dev check**: Passed before review (output shows 82 scenarios, 493 steps, all passed)
  > - **Acceptance tests**: All `@iteration-041` scenarios green; existing 039/040/019/020 scenarios unchanged and passing
  > - **Unit tests**: DeliveryReceipt projection, parser tests, router tests, email generation tests all passing
  > - **ADR conformance**: Implementation evidence confirms ADR-0048 header-based routing and ADR-0050 optimistic auto-follow pattern
  > - **Domain patterns**: Follows DDD (aggregates, entities, context boundaries), CQRS (separate commands/queries), event sourcing (events as facts, projections), and RDD (single responsibility, information expert)
  > - **Migration safety**: New `message_id` field on delivery_receipts with index; backward-compatible (nullable)
  > - **Working tree**: Clean at review start per preflight check
  > 
  > The implementation is production-ready with documented limitations. Bounded-safe refactorings improve maintainability but are optional. Judgement-worthy findings are real code-health signals but do not block merge.


You are independently reviewing the completed, plan-conforming implementation of the iteration plan at docs/iterations/041-reply-by-email-threading/plan.md.

Use the prior context: the plan text, collected implementation evidence, current working tree state, commit range from `108b67402cf434f05fa988a72bd67992052b623c..HEAD`, and the successful dev check output. Be strict, practical, and specific. Do not edit files.

This workflow reviews an already-committed implementation after the implementation workflow has proved plan conformance. The review job is code polish plus smell radar: refactoring, maintainability, project conventions, ADR conformance, and surfacing judgement-worthy non-blocking smells. Do not emit shell-command/tool-call JSON; return the Markdown review report only.

Use the project pattern reference docs as review guidelines when the touched code involves domain modeling, Commanded, aggregates, projections, event streams, read models, or object responsibility boundaries:

- `docs/reference/domain-driven-design.md`
- `docs/reference/cqrs.md`
- `docs/reference/event-sourcing.md`
- `docs/reference/responsibility-driven-design.md`

Treat accepted ADRs as binding project decisions. Treat these reference docs as design-quality guidance for interpreting and applying those ADRs, not as permission to override an ADR or the iteration plan.

Automated tests are the behavioural feedback loop in this workflow. If you find a likely behavioural gap, missing acceptance criterion, or inadequate automated coverage despite green dev check, flag it as a blocking issue requiring a new implementation/test pass or human decision; do not disguise it as refactoring feedback. Do not ask for feature-file edits.

Review against these questions:

0. ADR conformance
   - Read every ADR cited by the plan and any nearby/current ADRs under `docs/adr/` that govern touched architecture.
   - Follow signposts in those ADRs to the reference docs above; use them to check whether domain/CQRS/event-sourcing/RDD implementation choices match the patterns Memba wants.
   - Does the implementation obey accepted ADR decisions and consequences as binding constraints?
   - Does it avoid replacing ADR-mandated infrastructure or architecture with simpler local substitutes, unless the plan explicitly deferred that decision?
   - Do tests and implementation evidence prove the ADR-relevant behaviour, wiring, or structure?
   - Reject if the implementation conflicts with accepted ADRs or omits a cited ADR's central decision without an explicit plan deferral or human decision.

1. Light plan-fidelity sanity check
   - Does the implementation appear consistent with the stated goal and capability, given the plan-conformance gate has already passed?
   - Did it avoid obvious out-of-scope work?
   - If you find a substantial plan gap, classify it as blocking and requiring human input or a new implementation pass.

2. Behaviour and automated coverage
   - Did dev check pass before review?
   - Are important happy paths, edge cases, permissions, error states, and data/state changes covered by automated tests where appropriate?
   - Were acceptance feature files left unchanged as domain acceptance criteria?

3. Technical quality / refactoring
   - Are Phoenix, LiveView, HEEx, Ecto, Tailwind, and Elixir conventions followed where relevant?
   - Are migrations, schemas, contexts, tests, routes, UI, background jobs, and integrations coherent?
   - Is the implementation maintainable, minimal, and well factored?

4. Code-health classification
   - Blocking: ADR violations, behavioural gaps, missing or unsafe coverage, repeated blockers, or anything needing product/architecture judgement before merge.
   - Bounded-safe: concrete, low-risk refactoring, maintainability, convention, or test-quality fixes an agent can apply without changing product behaviour or feature files.
   - Judgement-worthy non-blocking: design smells, coupling, duplication, naming, dependency, or architecture drift that might merit human judgement later but should not block this merge.

Return a Markdown report with:

- Decision: ACCEPT or REJECT
- Confidence: High, Medium, or Low
- ADR conformance: PASS or FAIL
- ADR violations: numbered list with ADR number/file and implementation evidence
- Blocking issues: numbered list
- Bounded-safe fixes: numbered list
- Judgement-worthy non-blocking code-health findings: numbered list; for each include file(s), smell, and why it may need human judgement
- Suggested fixes: concrete changes if rejected or bounded-safe fixes exist
- Validation notes: tests/checks/manual checks relevant to the decision