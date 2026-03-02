# TeamBuilder — Pokemon Team Builder iPhone App

## What This App Does
TeamBuilder is an iPhone app that lets users build and evaluate Pokemon teams.
Users can browse all Pokemon, add them to named teams of up to 6, and get a score
showing how well-balanced the team is based on type coverage and base stats.

## Tech Stack
- **Language:** Swift
- **UI Framework:** SwiftUI
- **IDE:** Xcode (on Mac)
- **Pokemon Data:** PokeAPI (https://pokeapi.co) — free public API, all 1025 Pokemon (Gen 1–9)
- **Local Storage:** SwiftData (Apple's modern local database for Swift)
- **Target:** iOS 17+ iPhone Simulator

## App Screens

### 1. Pokedex Tab
- Browse all 1025 Pokemon in a scrollable grid
- Search by name, filter by type
- Tap a Pokemon to see: image, types, base stats, abilities
- "Add to Team" button on detail view

### 2. My Teams Tab
- List of all saved teams showing name, 6 Pokemon icons, and team score
- Button to create a new team (enter a name)
- Swipe to delete a team

### 3. Team Detail Screen
- Editable team name
- 6 Pokemon slots (tap empty slot to add, tap filled slot to remove)
- Team Score (0–100) displayed prominently
- Type Coverage section: what types this team hits super-effectively
- Weak Against section: types at least 2 Pokemon are weak to
- Strong Against section: types the team resists or is immune to

## Pokemon Rules
- Max 6 Pokemon per team
- No duplicate Pokemon on the same team
- Partial teams (fewer than 6) are allowed and can be saved
- No legendary/mythical restrictions — user decides

## Team Scoring Algorithm (0–100)

### Type Coverage — 40 pts
How many of the 18 types the team can hit super-effectively (offensively).
Full coverage of all 18 = 40 pts, scales proportionally.

### Type Defense Balance — 35 pts
Penalize stacking weaknesses to the same type across the team.
Bonus for resistances that cover common team weaknesses.

### Stat Balance — 25 pts
Reward teams with a spread of roles:
- At least one fast Pokemon (Speed > 100)
- At least one tank (HP + Defense > 160)
- At least one special attacker (Sp. Atk > 100)
Scores based on how many roles are covered.

## Data Notes
- Fetch all Pokemon names/IDs from PokeAPI on first launch, cache locally
- Fetch full Pokemon data (types, stats, sprite) on demand, cache after first load
- App should work offline after initial data load

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

## Build Order
1. Xcode project setup + SwiftData models
2. PokeAPI service layer (fetch + cache Pokemon)
3. Pokedex screen (browse + search)
4. Pokemon detail screen
5. Team storage (create, name, delete teams)
6. Team builder UI (6 slots, add/remove Pokemon)
7. Scoring algorithm
8. Type analysis display (strong against / weak against)
9. Polish (icons, colors, empty states, animations)
