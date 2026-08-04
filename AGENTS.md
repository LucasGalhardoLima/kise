# Agent notes — iOS / iOS 27

## Re-grounding

If you have compacted context or lost track of the project, re-read this file before editing.

## iOS 27 hazards — check these before shipping against a new SDK

**Forced on recompile — affects every app, no opt-out**
- **The Liquid Glass opt-out is being removed.** Recompiling with Xcode 27 forces the new design; there is no flag to defer it. Budget design/QA time even if the app needs no other migration work.
- **Resizability is automatic.** Rebuilding against the new SDK auto-opts the app into resizability on iPad and iPhone Mirroring. Custom views need Auto Layout + trait collections.

**Fatal**
- `UIScene` lifecycle is **mandatory**. Building against the latest SDK without a `UISceneDelegate` means the app does not launch. (A pure SwiftUI `App` satisfies this — the framework manages scenes. The risk is AppDelegate-only UIKit apps.)

**Silent failures — no compiler help, these reach users**
- **Wallet:** a pass carrying only a new iOS 27 barcode format renders *no barcode at all* on iOS 26. Keep a legacy fallback in the `barcodes` array.
- **RAW capture:** iPhone 17's front sensor is portrait-mounted. `AVCapturePhotoOutput` compensates by default — but never for Bayer RAW or ProRAW. Photos ship sideways.
- **App Intents:** Siri continues conversations across devices and Shortcuts syncs entities via iCloud. Locally-generated IDs (Core Data row IDs, per-install UUIDs) fail to resolve on a second device — use `SyncableEntity`.
- **Managed devices:** iOS 27 shows one consolidated privacy prompt at first launch. If the user allows, per-permission prompts never fire, so just-in-time priming UI may be unreachable.

**Layout**
- iPhone apps are fully resizable (Mirroring, iPhone-on-iPad). `userInterfaceIdiom` and `interfaceOrientation` are **dead as layout inputs**; Mirroring always reports portrait. `UIRequiresFullscreen` now means *discrete resizing*, not opt-out. Size classes and adaptive layout only.

**Source break**
- `@State` is now a macro. A default value *plus* assignment in `init` is an error — delete the default. (Upside: class instances in `@State` are initialized once; back-deploys to iOS 17 / macOS 14.)

**Server-side, if this app has a backend**
- Retention offers introduce `offerType: 5` — exhaustive switches over 1–4 break.
- Group/org subscriptions emit one transaction *per member*, not one with a quantity.

**Agentic / LLM features**
- Rate every tool action by side effect (financial / exfiltration / data loss / injection-persistence). Enforce at `.onToolCall` — throwing there blocks execution before the tool runs, and one site covers all tools. `.historyTransform` is scoped to a single inference iteration and must reapply.

## Free wins (no deployment-target bump)

- `ContentBuilder` cures "unable to type-check in reasonable time" — works at **any** deployment target, just compile with Xcode 27.
- `AsyncImage` now does standard HTTP caching automatically, no rebuild.
- Camera deferred start auto-opts-in on recompile against the iOS 26+ SDK with `AVCaptureVideoPreviewLayer` (~2× faster launch). Add `isResponsiveCaptureEnabled` for time-to-first-capture.
- `CIContext.memoryLimit` defaults to only 256 MB on iOS — raise to 512–1024 MB to speed Core Image exports.

## Full reference

Detailed notes for all 93 reviewed WWDC26 sessions, including per-area API tables and a deployment-target breakdown:

- `~/.claude/skills/apple-platform-updates/references/wwdc26/` — start at `00-index.md`, or `00-by-os-version.md` when planning a minimum-version bump
- Claude Code users: the `apple-platform-updates` skill loads this automatically

API names marked `(approx)` in those files were not verifiable from session transcripts alone — check developer documentation before writing code against them.
