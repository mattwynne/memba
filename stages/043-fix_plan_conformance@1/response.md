Plan conformance is now satisfied. The rerun gate identified one evidence-only gap: the manual browser demo required by [plan.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/plan.md:248) had not been recorded. I completed that demo successfully.

### Requirement-to-fix mapping

| Plan requirement | Repair and evidence |
|---|---|
| Manually demo ordinary and Admin members in one club | Used Kootenay Mountaineering Club with Alice as an ordinary member and Bob and Carol as active Admin members. |
| Verify group visibility and switching | Alice saw Everyone but no Admin. Bob saw Everyone and Admin and successfully switched to Admin. |
| Exercise a copied private-group link | Bob opened the copied Admin URL successfully. Alice received an ordinary 404 with no Admin group name disclosed. |
| Compose an Admin message | Bob composed “Committee meeting — manual conformance demo” from the selected Admin group. The compose form carried the Admin group ID. |
| Verify conversation access and recipients | Bob and Carol could open the resulting conversation. Alice received a non-disclosing 404. Delivery facts contained only Bob and Carol; Alice was absent. |
| Verify refresh/reopen behavior | Refreshing retained Bob’s Admin selection. Opening the fallback club home in a new page restored Admin from browser-local storage. |
| Verify inaccessible remembered-selection fallback | A forged remembered Admin selection for Alice safely fell back to Everyone; neither the Admin group nor its conversation appeared. |

The demo used these concrete IDs:

- Club: `clb_0c05de62-b122-493d-abe8-d9c3125d6db3`
- Everyone: `grp_cf656aa7-d796-d499-9de2-ee66e0d78077`
- Admin: `grp_44cf9be6-d6d8-ca45-d6cc-491c1d42959c`
- Admin message: `msg_f57cdc36-ea70-4fcc-8031-433f130f3b8f`

### Code and test changes

No production, test, configuration, migration, dependency, documentation, or acceptance-feature changes were needed. The repair brief specifically identified missing manual-validation evidence rather than missing behavior and directed that no files be changed if the demo passed.

The temporary manual browser driver was removed after use. There are no tracked or staged working-tree changes. The only untracked paths are the existing Fabro repair-baseline files under `.fabro/tmp/`.

No automated tests were added or changed because the sole gap required a manual demo. Existing automated validation remains applicable:

- Full `dev ci`: passed.
- Browser acceptance: 130 scenarios and 927 steps passed.
- All 22 implementation tasks remain checked in [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:24).
- `git diff --check`: passed.
- HEAD’s tree exactly matches the previously validated `dev_check` checkpoint `0c54e36`; later Fabro commits did not alter the tree.
- The independent conformance rerun returned `PLAN_CONFORMANT`.

There are no remaining plan gaps or human questions.