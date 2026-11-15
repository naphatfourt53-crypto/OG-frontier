# Phase 3: Campaign (8 missions, real transit, probes, endgame)

Date: 16 Nov 2026. Authority: team answers in this session.

## Decisions (team, 15-16 Nov)

| Question | Answer |
| --- | --- |
| Mars in the campaign | Robotic lander/rover with sample return path (Perseverance-style). Uses the probe system and Mars synodic window (780 d). Crew Mars round trip is NOT in this phase (needs ISRU and a new ship design). |
| Crew to Mars | Not in v0.5. Later: one-way + ISRU, a big redesign. |
| Probe travel | Real Hohmann transit (OrbitMath, calc). Probes arrive after the transit; the encounter is resolved by the player on arrival. |
| Deadline | Extended to real years. Campaign deadline is a game-tagged number of days; the epilogue is 180 days after the last completion. |
| Outer planets | Synodic periods and transits are calc from physics.json (std orbit constants). Costs, reward and minigame settings are game-tagged. |

## Feasibility (checked, see tools/check_physics.py)

- Crew Mars round trip: consumables 16.4 t for 3 crew x 900 d; a 200 t tank needs dry mass below 7.9 t; the ship cannot carry it. Not built.
- Best finish for 8 missions with real transit: about 11,570 days. Deadline 12,000 days leaves room for the epilogue.

## Clock model

- `day` is the Earth clock. Every day change goes through `GameState.advance_days(n)`.
- Probes in transit and encounters pending are processed inside `advance_days`.
- The Moon crew mission still runs its own days (9) and adds them on finish.

## Phases

1. Data: bodies (mercury, saturn, uranus, neptune) in physics.json; data/probes.json; campaign config.
2. GameState: campaign state, launch, windows, arrivals, completion, win/lose, save version 8.
3. Probe Control screen + encounters (station-keeping, gas scoop).
4. Endgame screen (win / lose), HUD day / deadline, station and menu links.
5. Hull floor for roll damage (deferred from Phase 1 review), Tech Book probes tab, docs, screenshots, package.

## Gates

check_physics.py ALL PASS, balance_check.py exit 0, mirror test PASS, smoke test PASS, screenshots with no SCRIPT ERROR, save v7 still loads.
