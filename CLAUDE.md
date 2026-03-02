# TeamBuilder — Pokemon Team Builder iPhone App

## What This App Does
TeamBuilder is an iPhone app that lets users build and evaluate Pokemon teams.
Users can browse all 1025 Pokemon, add them to named teams of up to 6, and get a
detailed analysis showing how well-balanced the team is — including type coverage,
weaknesses, role balance, fix suggestions, and threat awareness.

## Flow Diagram
A flow diagram (`FLOW.md`) documents the full user workflow and screen-to-screen
navigation of the app. It is created at the start of development and updated
whenever screens, flows, or features change. Always keep `FLOW.md` in sync with
the current state of the app.

## Tech Stack
- **Language:** Swift
- **UI Framework:** SwiftUI
- **IDE:** Xcode (on Mac)
- **Pokemon Data:** Bundled local JSON database (generated from PokeAPI at build time — no runtime API dependency for Pokemon data; sprites load from GitHub CDN; ability descriptions fetched on-demand from PokeAPI)
- **Local Storage:** SwiftData (Apple's modern local database for Swift)
- **Target:** iOS 17+ iPhone Simulator

## App Screens

### 1. Pokedex Tab
- Browse all 1025 Pokemon in a scrollable grid
- Search by name
- Filter by type (multi-type AND/OR logic)
- Filter by generation (Gen 1–9)
- Filter by stat thresholds (e.g. Speed > 100) via sliders
- Toggle to show/hide Legendary and Mythical Pokemon
- Sort by: Pokedex number, Base Stat Total, Speed, Attack, name A–Z
- **Team Compatibility Overlay:** when a team is active, each card shows:
  - Checkmark — already on the team
  - Green — safe to add
  - Orange — would create a type weakness overlap
- Long-press a card for a quick-add menu listing all saved teams
- Tap a Pokemon to open the detail screen

### 2. Pokemon Detail Screen
- Large sprite, name, types, generation
- **Stat bars** colored by value range (red = low, yellow = mid, green = high) with Base Stat Total
- **Full type matchup chart** — 18-type defensive grid showing 2x / 1x / 0.5x / 0x
- Abilities list with tap-to-expand plain-English descriptions
- **Evolution chain** with sprites — tap any stage to navigate to it
- **"How This Pokemon Fits Your Team"** section (when a team is active):
  - Types covered that the team currently lacks
  - Roles filled (Speed, Tank, Sp. Atk)
  - Weaknesses this Pokemon would add
- "Add to Team" button (opens team picker if multiple teams exist)

### 3. My Teams Tab
- List of all saved teams showing: name, format tag, 6 Pokemon sprites, and score
- **Score breakdown** — three sub-scores shown per team (Coverage / Defense / Stats)
- Button to create a new team (enter name + optional format tag)
- Swipe actions: delete, duplicate
- Tap a team to open Team Detail
- One team can be marked as **active** — drives Pokedex compatibility overlays and suggestions

### 4. Team Detail Screen
- Editable team name and format tag (Casual / OU / VGC / Nuzlocke / etc.)
- 6 Pokemon slots — tap empty slot to browse Pokedex, tap filled slot to remove
- **Drag to reorder** slots (long-press to drag)
- **Auto role labels** on each slot: Sweeper / Wall / Tank / Support / Pivot
- **Speed order panel** — team members ranked by Speed stat
- **Team Score (0–100)** displayed prominently with animated reveal
- Score broken into three labeled sub-scores: Coverage / Defense / Stats
- **Type Coverage Heatmap** — 18-type visual grid:
  - Green = team hits super-effectively
  - White = neutral coverage
  - Yellow = not very effective
  - Red = no coverage / immune
- **Shared Weaknesses** — severity-ranked:
  - Red: 3+ Pokemon weak to this type
  - Orange: 2 Pokemon weak to this type
- **Resistances** — types at least 2 Pokemon resist or are immune to
- **"Fix My Team" Suggestions** — actionable cards e.g.:
  - "3 Pokemon are weak to Fairy — consider adding a Steel or Poison type"
  - "No Pokemon faster than Speed 90 — consider a revenge killer"
- **Threat List** — top 5 Pokemon that threaten this team based on type matchups
- Export as Pokemon Showdown paste (share sheet)
- Import from Pokemon Showdown paste

## Pokemon Rules
- Max 6 Pokemon per team
- No duplicate Pokemon on the same team
- Partial teams (fewer than 6) are allowed and can be saved
- No legendary/mythical restrictions — user decides (filter available in Pokedex)

## Team Scoring Algorithm (0–100)

### Type Coverage — 40 pts
How many of the 18 types the team can hit super-effectively (offensively).
Full coverage of all 18 = 40 pts, scales proportionally.

### Type Defense Balance — 35 pts
Penalize stacking weaknesses to the same type across the team.
Bonus for resistances that cover common team weaknesses.
Severity weighting: types with 3+ weak Pokemon penalized more than 2.

### Stat Balance — 25 pts
Reward teams with a spread of roles:
- At least one fast Pokemon (Speed > 100)
- At least one tank (HP + Defense > 160)
- At least one special attacker (Sp. Atk > 100)
- At least one physical attacker (Attack > 100)
Scores based on how many roles are covered.

## Design System
- Use official Pokemon type colors throughout (Bulbapedia palette):
  - Fire = #F08030, Water = #6890F0, Grass = #78C850, Electric = #F8D030, etc.
- Stat bars: red (0–49), yellow (50–79), green (80–100+ scaled to 255 max)
- Haptic feedback:
  - Light: add Pokemon to team
  - Medium: team complete (6/6 filled)
  - Success: export / share

## Data Notes
- All 1025 Pokemon (types, stats, abilities, evolution chains) are bundled in `TeamBuilder/Resources/pokemon_data.json`, generated by `scripts/fetch_pokemon.py`
- `PokemonDatabase.seed(context:)` inserts all records into SwiftData on first launch (synchronous local file read — instant)
- Sprites load from GitHub CDN: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/{id}.png`
- Ability descriptions still fetched on-demand from PokeAPI when user taps to expand
- App works fully offline after first launch (sprites cached by iOS URL image caching)

## Onboarding (First Launch)
3-step swipeable intro (skippable):
1. What the app does
2. How the team score works (brief visual)
3. How to start building your first team

Note: no loading screen required on first launch — Pokemon data is bundled locally.

## Code Style
- Use SwiftUI for all views
- Use SwiftData for persistence (teams, cached Pokemon data)
- Use async/await for all network calls
- Keep views simple — separate business logic into model/service files
- User is a beginner — keep code readable and well-commented

## How to Run
1. Open the .xcodeproj file in Xcode
2. Select an iPhone Simulator (e.g. iPhone 16) from the device picker
3. Press the Play button (Cmd+R) to build and run

## Git Workflow
- **After every change or update**, commit and push to GitHub automatically
- Remote: `https://github.com/cgorelick13/TeamBuilder.git` (branch: `main`)
- When adding new Swift files or resources, run `xcodegen generate` before committing so the `.xcodeproj` stays in sync

## Build Order
1. Xcode project setup + SwiftData models
2. Local Pokemon database (`scripts/fetch_pokemon.py` generates JSON; `PokemonDatabase.swift` seeds SwiftData)
3. Onboarding flow
4. Pokedex screen (grid, search, filters, sort)
5. Pokemon detail screen (stats, type chart, abilities, evolution)
6. Team storage (create, name, tag, duplicate, delete teams)
7. Team builder UI (6 slots, roles, drag reorder, speed panel)
8. Scoring algorithm (coverage, defense, stats)
9. Type coverage heatmap + weakness severity
10. "Fix My Team" suggestions + Threat List
11. Team Compatibility Overlay in Pokedex
12. Active Team Context (cross-tab state)
13. Showdown export/import
14. Design polish (type colors, stat bars, haptics, animations, empty states)
15. Update FLOW.md to reflect final shipped state
