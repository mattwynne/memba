1. **Selected todo line**
   - `008 Run ./bin/dev gallery-walk and compare the club-home and conversation-page screenshots against design-system/wireframes/club-home.html and member-conversation.html.`

2. **Changes made**
   - No code/config/test changes.
   - Ran the gallery walk and reviewed the relevant generated screenshots:
     - `tmp/gallery/app__member-club-home__desktop.png`
     - `tmp/gallery/app__member-club-home-members-tab__desktop.png`
     - `tmp/gallery/app__member-message-read__desktop.png`
   - Rendered comparison wireframe screenshots into ignored local artifacts:
     - `tmp/designshots/club-home.png`
     - `tmp/designshots/member-conversation.png`
   - Confirmed the target visual changes are present:
     - Conversation rows show preview text.
     - “Recent club messages” is absent.
     - Members panel has no “Current members” heading.
     - Members tab has a single visible “Invite member” action in the tab-row slot.
     - Conversation page has no ORIGINAL MESSAGE/REPLY badges.
     - Conversation page has no duplicate “From …” meta line under the title/follow row.
     - Conversation title is at normal page-title scale rather than hero scale.

3. **Focused validation commands run**
   - `./bin/dev gallery-walk`
     - Passed.
     - Output included: `Captured 67 gallery screenshots in tmp/gallery` and `Wrote tmp/gallery/gallery.html`.
   - Rendered the two design wireframes with Playwright for side-by-side artifact comparison:
     - Passed.
     - Produced `tmp/designshots/club-home.png` and `tmp/designshots/member-conversation.png`.
   - `git status --short`
     - Only `todo.md` is modified after check-off.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Run ./bin/dev gallery-walk and compare the club-home and conversation-page screenshots against design-system/wireframes/club-home.html and member-conversation.html.`
   - To:
     - `- [x] 008 Run ./bin/dev gallery-walk and compare the club-home and conversation-page screenshots against design-system/wireframes/club-home.html and member-conversation.html.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan does not explicitly reference any ADRs.
   - This task was validation-only and did not alter architecture, behavior, or acceptance coverage.