//
//  JournalApp_DeveloperNotes.swift
//  Journal App
//
//  Human‑readable developer notes for this project. Keep this file in source control.
//  When you (or ChatGPT) say: "add to developer notes", append the note under the
//  "Developer Notes Log" section below.
//
//  This file is intentionally mostly comments so it does not affect the build.
//

import Foundation

/*
====================================================
Journal App — Developer Notes
====================================================

Purpose
- Single place to capture decisions, TODOs, and workflow tips.
- Append new entries at the bottom in the "Developer Notes Log" section with a timestamp.
- Serves as PERSISTENT MEMORY & VIRTUAL SWAP FILE across AI chat sessions.

How to use this file
- When you want to record something, add a new entry under "Developer Notes Log" like:
  [YYYY-MM-DD HH:MM] (author) Short description of the decision, idea, or TODO.
- Keep entries concise. If longer, add a sub‑bullet list.
- Example: "[2025-09-26 13:00] (MF) GitHub Actions removed - repository now for sync only."

Rules & Guidance for ChatGPT/Claude (Persistent Memory)
- When the user says "check the developer notes" or "add to developer notes", they mean THIS file: JournalApp_DeveloperNotes.swift.
- Do NOT write logs to any runtime-accessible file. Only append comments inside this file.
- Do NOT wire this file into the app at runtime (do not import/read/parse it from app code).
- Append new entries under the section "Developer Notes Log" using this format:
  [YYYY-MM-DD HH:MM] (AUTHOR) Message. Use MF for Michael Fluharty; use Claude for Claude entries; use ChatGPT for ChatGPT entries.
- Newest entries go at the TOP of the Project Status section; the Developer Notes Log can be chronological or reverse — keep newest at the top for quick scanning when requested.
- For multi-line notes, use simple "-" bullets. Avoid images and tables.
- If a note implies code changes, treat that as a separate, explicit task; do not change code unless requested.

CRITICAL WORKFLOW RULES:
- AI ASSISTANTS DO ALL HEAVY LIFTING: AI does 100% of coding, file creation, problem-solving, and technical work.
- USER DOES MINIMAL ACTIONS ONLY: User only performs actions that AI assistants are physically prohibited from doing in Xcode.
- STEP-BY-STEP SCREENSHOT METHODOLOGY: 
  * AI gives ONE specific, minimal instruction (e.g., "Click the + button", "Select this menu item")
  * User performs ONLY that single action
  * User takes screenshot showing the result
  * User uploads screenshot to AI
  * AI MUST PAUSE and wait for screenshot before giving next instruction
  * This creates a calm, methodical, stress-free workflow
- USER PREFERS XCODE-ONLY WORKFLOW: No terminal commands ever.
- FOCUS ON BUGS/ERRORS ONLY: Enhancements and new features go in notes only, not implemented unless fixing a bug.

- Commit message style: short, imperative, informative (e.g., "Fix journal entry save bug").
- When asked to "summarize developer notes", summarize ONLY content from this file; do not invent or reference external logs.
- When asked to "clear notes" or remove entries, confirm explicitly before deleting or truncating any log content.
- Treat this file as the single source of truth for decisions, conventions, and project-wide guidance.
- Only ChatGPT and Claude will read and work from this file. Treat it as the collaboration ledger for this project.
- Maintain a running section titled "Project Status & Chat Summary" in this file; after each working session, append a brief summary with timestamp, current context, key changes, and next steps.
- This file serves as continuity between chat sessions since AI assistants don't remember previous conversations.

GitHub & Repository Policy
- GitHub serves ONLY as backup and sync service between multiple development machines
- NO automated builds, testing, or CI/CD pipelines
- NO GitHub Actions workflows
- Repository is purely for: push from Machine A → pull on Machine B
- Keep repository clean and simple for code sync only

HISTORICAL CONTEXT (From Previous Session Files):
- LeftOff.swift revealed Journal App was never successfully launched - stuck in target/scheme configuration phase
- Previous chatbot had created complete 1076+ line iOS journal app (ContentView_iOS.swift) with full features
- App had camera integration, document scanning, iCloud sync, but wouldn't launch due to project configuration issues
- Error: "Cannot preview in this file - No selected scheme" prevented proper testing
- Mac Mini had limited simulators, MacBook had full iOS device provisioning
- MiniNotes files showed coordination challenges between workspace-scoped and project-scoped assistants
- ContentView files were removed from Xcode project (likely by previous chatbot attempting fixes)
- Nuclear rebuild approach chosen to avoid inherited configuration problems

Quick project snapshot
- Platform: Multi-platform SwiftUI app (iOS and macOS intended)
- Testing: Using modern Swift Testing framework
- Current state: Clean rebuild after nuclear deletion, zombie file cleanup in progress
- Architecture: Standard SwiftUI app structure with platform-specific views
- Main files: Journal_AppApp.swift (main app), ready for ContentView_iOS/macOS implementation

Coding conventions
- Swift 6, prefer SwiftUI and modern Swift patterns
- Use async/await for concurrency
- Keep UI in SwiftUI with NavigationStack and #Preview
- Focus on Apple platform best practices
- Multi-platform compatibility (iOS/macOS)

Data model summary
- JournalEntry: Core model with title, content, date, mood, image support (to be recreated)
- Platform-specific managers for iOS/macOS persistence (to be recreated)
- iCloud Drive integration with local fallback (to be recreated)

Persistence
- iOS: JournalManager with iCloud Drive + local Documents fallback (to be recreated)
- macOS: MacJournalManager with separate file (journal_entries_mac.json) (to be recreated)
- JSON-based storage with automatic migration (to be recreated)

====================================================
Project Status & Chat Summary
- [2025-09-26 15:50] (Claude) Session summary: Zombie file cleanup and developer notes recreation
  - User implemented smart zombie identification system using /* Zombie File */ markers
  - Confirmed logic: numbered files = zombies, clean unnumbered files should exist
  - Discovered clean JournalApp_DeveloperNotes.swift was missing from project
  - Recreated clean developer notes file with complete historical context and workflow rules
  - User's zombie marking strategy ensures safe cleanup without losing important content
  - Next steps: Complete zombie cleanup, then implement journal functionality
  - Status: Clean developer notes now available, zombie identification system working

- [2025-09-26 15:40] (Claude) Current session summary: Nuclear rebuild complete with full context documentation
  - Successfully completed nuclear deletion and clean rebuild of Journal App project
  - Analyzed complete file history including LeftOff.swift and MiniNotes coordination files
  - Identified root cause: Previous session had working 1076+ line journal code but launch configuration failures
  - Created foundational files: Journal_AppApp.swift with proper multi-platform structure
  - Project now has clean foundation without inherited configuration problems
  - Ready to implement complete journal functionality with proper launch configuration

- [2025-09-26 14:50] (Claude) Session summary: File analysis and nuclear option planning
  - Discovered user has complete working journal app code in loose files
  - Identified multiple duplicate files causing confusion
  - User has backup and chose nuclear deletion approach for clean rebuild
  - Planned systematic deletion of duplicates while preserving working functionality

====================================================
Developer Notes Log
- [2025-09-26 15:50] (Claude) Recreated clean JournalApp_DeveloperNotes.swift after confirming it was missing. User's zombie identification system working perfectly.
- [2025-09-26 15:45] (Claude) User implemented smart zombie marking strategy using /* Zombie File */ in numbered duplicates for safe identification and cleanup.
- [2025-09-26 15:40] (Claude) Added comprehensive current session summary documenting complete nuclear rebuild process and historical context analysis.
- [2025-09-26 15:35] (Claude) Added historical context from LeftOff.swift and MiniNotes files. Previous session had launch configuration issues that led to ContentView removal.
- [2025-09-26 15:30] (Claude) Nuclear rebuild: Created foundational files after user deleted duplicates. Clean slate ready for proper journal app implementation.
- [2025-09-26 14:05] (Claude) Added proper name attribution to timestamps in developer notes.
- [2025-09-26 14:00] (Claude) Added critical workflow rules: AI does all coding/heavy lifting, user does minimal Xcode actions only, screenshot methodology.
- [2025-09-26 13:55] (Claude) Created developer notes file and established persistent memory system for Journal App project.
- [2025-09-26 13:00] (Claude) GitHub Actions workflows removed - repository configured for sync-only usage as requested by user.

// Add new notes above this line. Keep newest entries at the top for quick scanning.
*/

public enum DeveloperNotesAnchor {}