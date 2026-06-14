# Memba

## Design system (claude.ai/design)

Designs are iterated **on the web** at claude.ai/design and pulled down here for implementation.

- **Project:** Memba
- **Type:** `PROJECT_TYPE_DESIGN_SYSTEM`
- **Project ID:** `bc97cfc3-436c-471e-a939-7ba222859282`
- **Owner:** Matt Wynne

### Workflow

The web design system is the **source of truth**. To implement a design:

1. Matt iterates on the Memba project at claude.ai/design.
2. Claude Code reads it **directly from the cloud** via the `DesignSync` tool
   (`list_files` to see structure, `get_file` to pull content). No export/zip needed —
   the project is a real design system, so it can be read live, on demand.
3. Claude implements against the pulled designs in this repo.

Pushing local changes back up to the design system (the reverse direction) is handled by
the user-triggered `/design-sync` skill, targeting `--project bc97cfc3-436c-471e-a939-7ba222859282`.

> History: Memba started as a regular (non-design-system) claude.ai project, which Claude
> Code cannot read. It was exported as a zip and re-created as a proper design-system
> project on 2026-06-13 so it can be read directly from then on. The zip was a one-time
> bootstrap and is gone.
