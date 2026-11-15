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
