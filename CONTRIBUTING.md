# Contributing to Inkwell Journal App

Thank you for helping improve the project! This document captures how we work together.

## Communication & Guidance
- Be explicit and detailed in your instructions — describe each step clearly (e.g., which button to click).
- Assume I say yes to be proactive, but tell me what you did.
- Prefer small, focused changes that are easy to review and revert if necessary.

## Consistency
- Use the standard section title format: YYYY MON DD - HHmm - Title (e.g., 2025 SEP 17 - 1151 - Example).
- Keep terminology and capitalization consistent (e.g., “tweaks” not “tweeks”, “synchronization” not “syncronization”).
- Prefer consistent file naming and document structure (README, Docs/Backlog.md, Docs/Postmortems/...).

## Developer Notes
- Canonical developer notes live in `DeveloperNotes.swift` (top-level comment block).
- Major incidents and learnings also get a dedicated doc under `Docs/Postmortems/`.

## Tasks & Backlog
- Open tasks, suggestions, and ideas are tracked in `Docs/Backlog.md`.
- Use this template for new tasks:
  - Title
  - Description
  - Owner
  - Priority (Low/Medium/High)
  - Due date
  - Acceptance criteria (bullets)

## Branching & Commits (suggested)
- main: always buildable
- feature/<short-name>: for new work
- fix/<short-name>: for fixes
- Commit messages: present tense, concise, reference the area (e.g., `docs: add 2025-09-17 postmortem`).

## Code Style
- Prefer Swift Concurrency (async/await) where appropriate.
- Keep platform-conditional code clean using `#if os(...)` blocks.
- Add comments for non-obvious decisions.

## Testing
- Prefer lightweight, focused tests. Use Swift Testing where possible.
- UI tests should avoid flakiness; prefer deterministic checks.

