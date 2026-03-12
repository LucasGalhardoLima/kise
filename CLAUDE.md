# KISE

Intelligent wardrobe consultant — native iOS app (Swift/SwiftUI).

## Project Overview

KISE helps people dress with intention by combining their wardrobe pieces, style preferences, local weather, and daily context to suggest outfits. Built with SwiftUI, powered by Claude API for outfit suggestions.

## Design Spec

See `docs/superpowers/specs/2026-03-11-kise-design.md` for the full design specification.

## Tech Stack

- **Platform:** iOS native (Swift / SwiftUI)
- **Data:** SwiftData (on-device)
- **Weather:** WeatherKit
- **Suggestion engine:** Claude API via thin proxy server
- **Catalog images:** Pre-generated, bundled as app assets

## Key Principles

- All user data stays on-device (SwiftData)
- Proxy server is stateless — no user data stored server-side
- Privacy-first: no accounts, no tracking
- Aesthetic: minimalist, off-white, serif headings, zero noise
