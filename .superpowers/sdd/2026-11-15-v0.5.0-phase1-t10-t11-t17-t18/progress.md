# SDD ledger — plan: docs/superpowers/plans/2026-11-15-v0.5.0-phase1-t10-t11-t17-t18.md

Ruling: working directly on `main` — the project's established workflow across this whole engagement is commit+push to `main` after every change (user standing instruction); that is explicit consent to work on main. No feature branch. Cost if wrong: none practical (single-developer repo).
Ruling: sdd-workspace/task-start/task-done are POSIX scripts and this host is Windows PowerShell with a Thai path — ledger and workspace are maintained manually at .superpowers/sdd/2026-11-15-v0.5.0-phase1-t10-t11-t17-t18/. Cost if wrong: none (same artifact, hand-managed).

Pre-flight: Task4 produces `activities()/resolve_nav/resolve_burn/set_thermal_roll/set_exercise_hours/stamina_capacity_mult` + run fields → Task5 (flight.gd) and Task6 (explore) consume. Consistent names in plan.
Pre-flight: Task6 produces `finish_explore(points, counts, stamina_btu, eva_food_kcal, eva_time, sample_kg := 0.0, walks_log := [], deploys := 0)` → Task7 and old smoke `_play()` callers consume; defaults keep old callers green. OK.
Pre-flight: Task4 smoke `_play()` gains "nav"/"burn" handling BEFORE GameState returns those kinds (test-first order preserved). OK.
Pre-flight: Task5 screenshots consume `show_nav/show_burn/open_schedule` defined in the same task. OK.

Task 1: complete (commits 2254a4a..af6161c, tests: tools/check_physics.py -> ALL PASS exit 0)
Task 2: complete (commits af6161c..a8588e3, tests: tests/test_stamina_physics_farm.gd -> PASS 18 checks)
  Ruling: Farm.led_kwh_per_m2_day takes (ppfd, efficacy, photoperiod_h) - plan wrote 2 args; used the real signature (300.0, 2.5, 16.0) = 1.92. Cost if wrong: none.
  Ruling: T10 is a verification test of existing code - no artificial red phase; plan's Expected was PASS.
Task 3: complete (commits a8588e3..98bd724, tests: smoke PASS 161 + mirror PASS 18 + check_physics ALL PASS)
  Ruling: T11 audit found every AC item already implemented except the stamina-bar tooltip - closed that gap only.
Task 4: complete (commits 98bd724..17d60a2, tests: smoke -> PASS 180 checks exit 0, check_physics ALL PASS, balance_check exit 0)
  Ruling: worst-case dv penalty test uses resolve_nav(0.0)+resolve_burn(0.0) (penalty 12.37), not resolve_nav(1.0) as the plan's step text said - the formula extra = 6.0*(1-nav_avg) requires accuracy 0. Cost if wrong: none (formula is the authority).
  Ruling: roll damage asserted same-seed relative (hull_on - hull_off == 12.0) instead of absolute 88.0 - event choices also change hull. Cost if wrong: none (same seed -> identical events).
Task 5: complete (commits 17d60a2..6715da1, tests: smoke PASS 180, screenshots 21 OK, balance_check exit 0)
  Ruling: launch checklist shows when plan_i == 0 (not run.step, which advance() no longer updates); set_progress() now maps plan_i/plan.size() onto the ship arc.
  Ruling: burn finishes on release-after-hold OR auto at burn_hold_s - an instant release ends with fraction ~0 and a full penalty.
Task 6: complete (commits 6715da1..75672d3, tests: smoke -> PASS 190 checks, screenshots 21 OK, balance exit 0)
  Ruling: launch checklist shows when plan_i == 0 (not run.step, which advance() no longer updates); set_progress() now maps plan_i/plan.size() onto the ship arc.
Task 7: complete (commits 75672d3..bedddf7, tests: smoke -> PASS 191 checks, screenshots 23 OK, check_physics ALL PASS, balance exit 0)
  Ruling: prep panel shows before walk 1 instead of auto-starting; _test_t18 confirms prep first (plan's step text predates the panel).
  Ruling: jettison drops whole resource types (not per-piece) - simplest honest UI; points and ore both lost.
  Ruling: document/core/deploy holds pause movement; core forces hard pace, other holds drain at easy.
Task 8: complete (commits bedddf7..f3c052e, tests: smoke PASS 191, mirror PASS 18, check_physics ALL PASS, balance exit 0 incl. T17 worst-case line)
  Ruling: the Godot editor rewrote project.godot during a windowed run and dropped the explicit `renderer/rendering_method` desktop+web lines - defaults are identical (forward_plus / gl_compatibility for web), so this is benign; verified via the property list earlier.
Final review: review range 2254a4a..f3c052e (merge base 2254a4a), dispatch fresh reviewer.
Final review: received (no Critical). Fix pass committed as 22b2c64.
Final: fixed burn soft-lock — smoke "burn auto-resolves when the player never presses" + "skipped burn leaves the full nominal penalty" RED->GREEN, suite 199/199, screenshots 23 OK.
Final: fixed hardcoded multipliers — stamina penalty now reads no_exercise_stamina_capacity_penalty_pct (pinned by "capacity penalty reads activities.json"); document/core multipliers via _doc_multiplier/_core_multiplier helpers wired to activities.json (pinned by wiring checks) RED->GREEN, suite green.
Final: fixed hold-not-holding (re-graded Minor->Important: spec says "hold to drill"; a tap committed 5 s of forced hard pace) — "hold cancels when the key is not down" + "cancelled hold grants no points" RED->GREEN; key-release latch stops chained holds.
Final: Ruling: overshoot negative penalty (reviewer minor 3) - deferred, not fixed; overshoot clamps at 1.2 in resolve_burn and the auto-finish fires at exactly hold_s in practice. Cost if wrong: ~0.04 m/s discount on one leg.
Final: Ruling: Mars delayed-comms dormant (declined item 1) - stands; mechanism ships dormant until phase 3 adds Mars data. Cost if wrong: none.
Final: Ruling: roll-skip scaling on long coasts (declined item 2) - stands for now; 2%/day on a 972 d Mars trip would zero hull silently. Phase 3 Mars mission must clamp hull to a floor + _fail at 0. Cost if wrong: a phase-3 bug.
Final: Ruling: "Coast to the Moon" labels hardcoded (declined item 3) - stands; cosmetic until Mars lands. Cost: label text only.
Final: Ruling: destinations.json imported verbatim (declined item 4) - stands; team data, not code.
Final: Ruling: eva_window_s 75 vs settings 60 (declined item 5) - stands; team-ruled, logged in OVERNIGHT_LOG.
Final: Ruling: run length vs 5-min anti-goal (declined item 6) - stands; team approved 60s x 3 in spec section 7.
Final: Ruling: core bonus is 10 pts (2.0 x regolith 5 pts), not the plan's 20 - data is the authority; plan example used wrong regolith value. Cost if wrong: none (formula follows game_data.json).
Final: minor (deferred): jettison keeps x1.5 for documented samples (points refunded at base value).
Final: minor (deferred): deploy bonus points appear in no walk's breakdown (added before _walk_start_pts).
Final: minor (deferred): "Samples returned: 0 kg (N pieces)" cosmetic contradiction when sample_kg defaults.
Final: minor (deferred): resolve_nav index semantics test-fragile (pending_nav overwritten by repeated direct calls).
Final: minor (deferred): stringly-typed roll-damage trigger on the consume label.
Final: Ruling: no branch to merge (project convention = direct main pushes); finishing-a-development-branch skipped; phase 1 is live on main at 22b2c64.
Final review: clean after fix pass - no Critical/Important outstanding.
