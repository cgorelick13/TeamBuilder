# TeamBuilder — App Flow Diagram

> This document is the source of truth for all screen navigation and user workflows.
> Update it whenever screens, flows, or features change.

---

## App Launch Flow

```
┌─────────────────────────────────────────────────────────────┐
│                         App Launch                          │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
        First Launch                   Returning User
              │                               │
              ▼                               ▼
    ┌──────────────────┐           ┌──────────────────────┐
    │  Onboarding Flow │           │   Main Tab View      │
    │  (3 swipe cards) │           │  (last active tab)   │
    └──────────────────┘           └──────────────────────┘
              │
              ▼
    ┌──────────────────────┐
    │    Main Tab View     │
    │  (Pokedex tab open)  │
    │  Pokemon data seeded │
    │  instantly from      │
    │  bundled JSON        │
    └──────────────────────┘
```

---

## Main Navigation

```
┌─────────────────────────────────────────────────────────────┐
│                      Main Tab View                          │
│                                                             │
│    ┌─────────────────────┬─────────────────────────┐       │
│    │    Pokedex Tab      │      My Teams Tab        │       │
│    │    (Tab 1)          │      (Tab 2)             │       │
│    └─────────────────────┴─────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

---

## Tab 1: Pokedex

```
┌─────────────────────────────────────────────────────────────┐
│                        Pokedex Tab                          │
│                                                             │
│  [Search Bar]                                [Sort ▾]       │
│  [Type Filter] [Gen Filter] [Stat Filter] [Legendary ⚡]    │
│                                                             │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐              │
│  │   ✓    │ │   +    │ │   ⚠️   │ │   +    │  ← overlays  │
│  │[sprite]│ │[sprite]│ │[sprite]│ │[sprite]│              │
│  │Bulba.. │ │Charm.. │ │Squirt. │ │Pika..  │              │
│  └────────┘ └────────┘ └────────┘ └────────┘              │
│  (already   (safe     (adds      (safe                      │
│   on team)   to add)  weakness)  to add)                   │
└─────────────────────────────────────────────────────────────┘
       │                          │
    Tap card               Long-press card
       │                          │
       ▼                          ▼
 Pokemon Detail          ┌─────────────────┐
    Screen               │  Quick-Add Menu │
                         │  > Team Alpha   │
                         │  > Team Beta    │
                         │  > Team Gamma   │
                         └─────────────────┘
                                  │
                            Select a team
                                  │
                                  ▼
                         Pokemon added to team
                         (light haptic feedback)
```

### Pokedex Filters Detail

```
┌─────────────────────────────────────────────────────────────┐
│                       Filter Panel                          │
│                                                             │
│  Type Filter (multi-select, OR logic):                      │
│  [Fire] [Water] [Grass] [Electric] ...                      │
│  Tap to toggle — grid updates instantly                     │
│                                                             │
│  Generation:                                                │
│  [All] [Gen 1] [Gen 2] [Gen 3] ... [Gen 9]                 │
│                                                             │
│  Min Stats (number inputs):                                 │
│  HP: [___]   Atk: [___]                                     │
│  Def: [___]  Sp.Atk: [___]                                  │
│  Sp.Def: [___]  Speed: [___]                                │
│                                                             │
│  [ ] Show Legendaries / Mythicals                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Pokemon Detail Screen

```
┌─────────────────────────────────────────────────────────────┐
│  ← Back                    #006 Charizard                   │
│                                                             │
│                    [Large Sprite]                            │
│                   [Fire]  [Flying]                           │
│                                                             │
│  Base Stats ───────────────────────────────────────────     │
│  HP        78  ████████░░░░░░░  (yellow)                    │
│  Attack    84  █████████░░░░░░  (yellow)                    │
│  Defense   78  ████████░░░░░░░  (yellow)                    │
│  Sp. Atk  109  ████████████░░░  (green)                     │
│  Sp. Def   85  █████████░░░░░░  (yellow)                    │
│  Speed    100  ███████████░░░░  (green)                     │
│  Total    534                                               │
│                                                             │
│  Type Matchup Chart ───────────────────────────────────     │
│  [Nor][Fir][Wat][Ele][Gra][Ice][Fig][Poi][Gro][Fly]...     │
│  [ 1x][.5x][2x][2x][.5x][2x][.5x][.5x][ 0x][.5x]...      │
│                                                             │
│  Abilities ─────────────────────────────────────────────    │
│  Blaze     ▶ (tap to expand description)                    │
│  Solar Power ▶                                              │
│                                                             │
│  Evolution Chain ───────────────────────────────────────    │
│  [Charmander] → [Charmeleon] → [Charizard]                  │
│      Lv.16 ↗             Lv.36 ↗                            │
│                                                             │
│  ── How This Fits Your Team (Team Alpha active) ──          │
│  ✅ Covers 3 new types: Fire, Flying, Dragon                │
│  ✅ Fills Special Attacker role                             │
│  ⚠️  Adds 2nd Pokemon weak to Rock                          │
│                                                             │
│         [ + Add to Team Alpha ]                             │
└─────────────────────────────────────────────────────────────┘
              │                        │
      "Add to Team Alpha"       "Add to Team..."
              │                        │
              ▼                        ▼
     Added to active team      Team Picker Sheet
     (light haptic)            > Team Alpha
                               > Team Beta
                                       │
                               Select team → Added
```

---

## Tab 2: My Teams

```
┌─────────────────────────────────────────────────────────────┐
│  My Teams                              [ + New Team ]       │
│                                                             │
│  ┌───────────────────────────────────────────────────┐     │
│  │ ⭐ Team Alpha          [Casual]        Score: 82   │     │
│  │ [⬡][⬡][⬡][⬡][⬡][⬡]   Cov:38 Def:28 Stat:16     │     │
│  └───────────────────────────────────────────────────┘     │
│  ← swipe left: [Duplicate] [Delete]                         │
│                                                             │
│  ┌───────────────────────────────────────────────────┐     │
│  │   Team Beta            [VGC]           Score: 61   │     │
│  │ [⬡][⬡][⬡][  ][  ][  ]  Cov:24 Def:22 Stat:15    │     │
│  └───────────────────────────────────────────────────┘     │
│                                                             │
│  ┌───────────────────────────────────────────────────┐     │
│  │   Team Gamma           [OU]            Score: 74   │     │
│  │ [⬡][⬡][⬡][⬡][⬡][⬡]   Cov:32 Def:27 Stat:15     │     │
│  └───────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
         │                              │
     Tap a team                  [ + New Team ]
         │                              │
         ▼                              ▼
   Team Detail Screen          ┌─────────────────┐
                               │  New Team Sheet  │
                               │  Name: ________  │
                               │  Format: [▾]     │
                               │  [Cancel] [Save] │
                               └─────────────────┘
```

---

## Team Detail Screen

```
┌─────────────────────────────────────────────────────────────┐
│  ← Back          [Team Alpha]  [Casual ▾]   [Share ↑]      │
│                                                             │
│  ─── Pokemon Slots (drag to reorder) ──────────────────     │
│  ┌──────┐ ┌──────┐ ┌──────┐                                │
│  │[⬡]  │ │[⬡]  │ │[⬡]  │                                │
│  │Venusaur│Charm.│Blastoise                                 │
│  │ Wall │ │Sweep.│ │ Tank │  ← role labels                  │
│  └──────┘ └──────┘ └──────┘                                │
│  ┌──────┐ ┌──────┐ ┌──────┐                                │
│  │[⬡]  │ │[⬡]  │ │  +   │                                │
│  │Pikachu│Gengar│ (empty) │                                │
│  │Sweep.│Support│         │                                │
│  └──────┘ └──────┘ └──────┘                                │
│                                                             │
│  Tap filled slot → Remove Pokemon                           │
│  Tap empty slot  → Go to Pokedex (active team context)      │
│  Long-press + drag → Reorder slots                          │
│                                                             │
│  ─── Speed Order ──────────────────────────────────────     │
│  1. Gengar    130  ████████████                             │
│  2. Pikachu   110  ██████████                               │
│  3. Charizard 100  █████████                                │
│  4. Blastoise  78  ███████                                  │
│  5. Venusaur   80  ███████                                  │
│                                                             │
│  ─── Team Score ───────────────────────────────────────     │
│                        82 / 100                             │
│         Coverage: 38/40  Defense: 28/35  Stats: 16/25      │
│                                                             │
│  ─── Type Coverage Heatmap ────────────────────────────     │
│  [Nor][Fir][Wat][Ele][Gra][Ice][Fig][Poi][Gro][Fly]        │
│  [🟢 ][🟢 ][🟢 ][🟢 ][🟢 ][🟢 ][⬜ ][🟢 ][🟢 ][🟢 ]       │
│  [Psy][Bug][Roc][Gho][Dra][Dar][Ste][Fai]                  │
│  [🟢 ][🟢 ][🟡 ][🟢 ][🔴 ][🟢 ][⬜ ][⬜ ]                  │
│  🟢 Super-effective  ⬜ Neutral  🟡 Not very effective  🔴 No coverage │
│                                                             │
│  ─── Shared Weaknesses ────────────────────────────────     │
│  🔴 Ground    — 3 Pokemon weak (Pikachu, Charizard, Gengar) │
│  🟠 Psychic   — 2 Pokemon weak (Gengar, Venusaur)           │
│                                                             │
│  ─── Resistances ──────────────────────────────────────     │
│  Water, Grass, Fighting, Bug, Fairy                         │
│                                                             │
│  ─── Fix My Team ──────────────────────────────────────     │
│  ⚡ 3 Pokemon are weak to Ground — add a Flying or Levitate │
│  ⚡ No Dragon coverage — consider a Dragon or Ice type      │
│  ⚡ 1 empty slot remaining                                  │
│                                                             │
│  ─── Threat List ──────────────────────────────────────     │
│  1. Garchomp    — Dragon/Ground, hits 4 of your 5           │
│  2. Alakazam    — Psychic, hits Gengar + Venusaur            │
│  3. Rhydon      — Rock/Ground, hits 3 of your 5             │
│  4. Tyranitar   — Rock/Dark, hits 3 of your 5               │
│  5. Earthquake  — Ground coverage, threatens 3              │
└─────────────────────────────────────────────────────────────┘
         │                              │
  Tap empty slot               [Share ↑] button
         │                              │
         ▼                              ▼
  Pokedex Tab                  ┌─────────────────────┐
  (active team context,        │  Export Options      │
   compatibility overlays on)  │  > Showdown Paste   │
                               │  > Import from Paste│
                               └─────────────────────┘
```

---

## Active Team Context Flow

```
                    ┌─────────────────────┐
                    │   My Teams Tab      │
                    │   Mark team as ⭐   │
                    └─────────────────────┘
                              │
                    Active team is set
                    (persists across tabs)
                              │
              ┌───────────────┴──────────────┐
              │                              │
              ▼                              ▼
     Pokedex Tab                    Pokemon Detail
     Shows compatibility            Shows "How This
     overlay on each card           Fits Your Team"
     based on active team           section
```

---

## Showdown Export / Import Flow

```
Export:                              Import:

Team Detail                          Team Detail
[Share ↑]                            [Share ↑]
    │                                    │
    ▼                                    ▼
Showdown Paste                   Import from Paste
text generated                   Sheet opens
    │                                    │
iOS Share Sheet                  Paste Showdown
(copy, AirDrop,                  format text
 Messages, etc.)                         │
                                         ▼
                                  App parses names,
                                  looks up Pokemon
                                  in local cache,
                                  creates new team
```

---

## State Legend

| Symbol | Meaning |
|--------|---------|
| ⭐ | Active team (drives overlays + suggestions) |
| ✓ / ✅ | Pokemon already on team / positive signal |
| ⚠️ / ⚡ | Warning — weakness or issue |
| 🟢 | Super-effective coverage |
| ⬜ | Neutral / no data |
| 🟡 | Not very effective coverage |
| 🔴 | No coverage / shared weakness (3+) |
| 🟠 | Shared weakness (2) |
| [⬡] | Pokemon sprite slot |
| [  ] | Empty team slot |
