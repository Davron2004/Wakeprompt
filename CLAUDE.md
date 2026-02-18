# WakePrompt — Project Instructions

## Source of Truth

`AIAlarm_PRD_v2.md` (project root) is the canonical product spec.
Check it before adding features, changing architecture, or resolving ambiguity about intended behavior.

Current phase: **Phase 0 — Reliability Gate**
Exit criteria: 50+ on-device test alarms, 0 silent failures, documented fallback in each forced failure case.

---

## Project Structure

```
Wakeprompt/                        ← project root (.xcodeproj lives here)
├── AIAlarm_PRD_v2.md              ← product spec (source of truth)
├── CLAUDE.md                      ← this file
├── Wakeprompt/                    ← app source (file-system sync; all .swift here auto-compile)
│   ├── WakepromptApp.swift
│   ├── Models/
│   ├── Orchestration/
│   ├── Services/
│   │   └── Protocols/
│   ├── ViewModels/
│   ├── Views/
│   │   └── Components/
│   └── Intents/
└── WakepromptWidget/              ← widget extension source
```

Do NOT put `.swift` files at the project root or in `WakepromptWidget/` unless they belong to those targets.

---

## Coding Preferences

### General
- Always read a file before editing it. Never suggest changes to code you haven't seen.
- Ask before creating new files. Prefer editing existing ones.
- No over-engineering. No premature abstractions. No helpers for one-time use.
- Minimum complexity for the task at hand.

### Comments
- No comments unless the logic is genuinely non-obvious.
- No docstrings, no `// MARK:` sections, no explanatory comments on self-evident code.

### UI Style — Single Source of Truth
All repeated UI values (colors, corner radii, spacing, typography, animation parameters) must be declared once and referenced everywhere. No magic literals scattered across views.

The design system lives in `Wakeprompt/Views/Theme.swift` (create it when the first style constant is needed).

Example pattern:
```swift
// Theme.swift
extension Color {
    static let appBackground = Color("AppBackground") // or a literal, declared once
}

extension CGFloat {
    static let cardCornerRadius: CGFloat = 16
}
```

Then in views:
```swift
.background(Color.appBackground)        // not Color(hex: "#1A1A1A")
.cornerRadius(.cardCornerRadius)        // not 16
```

- Reuse existing views and components before building new ones.
- UI style must be visually consistent across all screens.
- If a new view deviates from established patterns, flag it rather than silently introducing a new style.
