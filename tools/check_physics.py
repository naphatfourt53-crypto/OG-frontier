#!/usr/bin/env python3
"""Mirror of scripts/physics.gd, stamina.gd, farm.gd in Python (Godot is not needed).
Run: python3 tools/check_physics.py   -> exits 1 if any check fails.
Every expected number below comes from the Game Data Book. If you change a JSON value,
update the Data Book first, then this file."""
import json, math, os, sys
ROOT = os.path.join(os.path.dirname(__file__), "..")
def load(n): return json.load(open(os.path.join(ROOT, "data", n + ".json")))
ST, PH, FA = load("stamina"), load("physics"), load("farm")
K = PH["constants"]; B = PH["bodies"]
fails = []
def check(name, got, want, tol):
    ok = abs(got - want) <= tol
    print(("PASS " if ok else "FAIL ") + f"{name}: got {got:.4f}, want {want} (+/-{tol})")
    if not ok: fails.append(name)

# ---- physics mirror
def hohmann_days(r1, r2, mu): a = (r1 + r2) / 2; return math.pi * math.sqrt(a**3 / mu) / K["seconds_per_day"]
def hohmann_dv(r1, r2, mu):
    a = (r1 + r2) / 2; v1 = math.sqrt(mu / r1); v2 = math.sqrt(mu / r2)
    return abs(math.sqrt(mu * (2 / r1 - 1 / a)) - v1) + abs(v2 - math.sqrt(mu * (2 / r2 - 1 / a)))
def planet_days(a, b): return hohmann_days(B[a]["a_au"] * K["au_m"], B[b]["a_au"] * K["au_m"], K["mu_sun_m3_s2"])
def synodic(p1, p2): return 1 / abs(1 / p1 - 1 / p2)
def stay_outer(i, o):
    t = planet_days(i, o); ni = 2 * math.pi / B[i]["period_days"]; no = 2 * math.pi / B[o]["period_days"]
    d = no - ni; phi_a = (math.pi - no * t) + d * t; phi_r = ni * t - math.pi
    return ((phi_r - phi_a) / d) % (2 * math.pi / abs(d))
def solar(r_au): return K["solar_constant_w_m2"] / r_au**2

R_EARTH_ORBIT_MOON = 384400e3  # mean Earth-Moon distance, m (standard value)
R_LEO = 6378137 + 400e3        # 400 km altitude, m (game choice, calc only)
check("Mars Hohmann one-way (d)", planet_days("earth", "mars"), PH["reference_trips"]["mars_hohmann_one_way_days"], 0.1)
check("Mars Hohmann one-way (d) vs Data Book 258.9", planet_days("earth", "mars"), 258.9, 0.1)
check("Earth-Moon Hohmann (d) from Earth centre to lunar distance", hohmann_days(R_LEO, R_EARTH_ORBIT_MOON, K["mu_earth_m3_s2"]), 4.98, 0.05)
check("Synodic Earth-Mars (d)", synodic(B["earth"]["period_days"], B["mars"]["period_days"]), 779.9, 0.1)
check("Mars stay (d)", stay_outer("earth", "mars"), 454.0, 1.0)
check("Mars round trip (d)", 2 * planet_days("earth", "mars") + stay_outer("earth", "mars"), 972.0, 2.0)
check("Apollo 11 coast hours -> days", PH["reference_trips"]["earth_moon_apollo11_coast_hours"] / 24, 3.04, 0.01)
check("Mars irradiance (W/m2)", solar(B["mars"]["a_au"]), 586.2, 0.1)
check("Earth irradiance (W/m2)", solar(1.0), 1361.0, 0.001)
check("Moon night (d) = half synodic month", PH["moon_surface"]["synodic_month_days"] / 2, PH["moon_surface"]["night_days"], 0.01)
check("Hohmann dv Earth->Mars (km/s) positive and plausible", hohmann_dv(K["au_m"], B["mars"]["a_au"] * K["au_m"], K["mu_sun_m3_s2"]) / 1000, 5.6, 0.2)

# ---- stamina mirror
rate = ST["rate_btu_per_hr"]; ts = ST["time_scale_h_per_game_s"]; cap = ST["capacity_btu"]
drain = lambda p: rate[p] * ts
check("Normal pace drain (Btu per game s)", drain("normal"), 93.0, 0.001)
check("Open-loop normal-pace seconds to empty", cap["open_loop"] / drain("normal"), 59.7, 0.05)
check("Open-loop easy-pace seconds to empty", cap["open_loop"] / drain("easy"), 71.15, 0.05)
check("Open-loop hard-pace seconds to empty", cap["open_loop"] / drain("hard"), 46.25, 0.05)
check("Burst budget drain (Btu) for 3 s", drain("burst") * ST["burst_max_s"], 600.0, 0.001)
check("No-exercise capacity for Open-loop", cap["open_loop"] * (1 - ST["no_exercise_capacity_penalty_pct"]), 4995.0, 0.01)
check("Reserve threshold (Btu) for Open-loop", cap["open_loop"] * ST["reserve_pct"], 832.5, 0.01)
check("EVA food for 6 h (kcal)", ST["eva_food_kcal_per_h"] * 60 * ts, 1200.0, 0.01)

# ---- farm mirror
dli = lambda ppfd, h: ppfd * h * 3600 / 1e6
led_w = lambda ppfd, eff: ppfd / eff
check("DLI 300 umol x 16 h", dli(300, 16), 17.28, 0.001)
check("LED W/m2 at 300 umol, eff 2.5", led_w(300, FA["led_efficacy_umol_per_j"]), 120.0, 0.001)
check("LED kWh/m2/day, 16 h", led_w(300, 2.5) * 16 / 1000, 1.92, 0.001)
let = FA["crops"]["lettuce"]
check("Lettuce kg/m2 per cycle (f=1)", let["edible_g_fw_m2_d"] * let["growth_days"] / 1000, 3.68, 0.005)
check("Lettuce DLI factor at 17.28 vs 17", min(1.0, 17.28 / let["dli_mol_m2_d"]), 1.0, 1e-9)
check("Lettuce half light -> factor", min(1.0, dli(150, 16) / let["dli_mol_m2_d"]), 0.5082, 0.001)
check("Crop count", len(FA["crops"]), 9, 0)


# ---- destinations and activities (second data set)
DE, AC = load("destinations"), load("activities")
RB = AC["real_basis"]; G = AC["game"]
check("Apollo 11 coast: 75:49:50.4 - 2:44:16 (h)", (75+49/60+50.4/3600)-(2+44/60+16/3600), RB["apollo11_coast_hours"], 0.01)
check("Nav sighting 6 h as fraction of coast", 6/RB["apollo11_coast_hours"], G["transit"]["nav_sighting"]["trigger_fraction_of_trip"][0], 0.001)
check("Nav sighting 24 h as fraction of coast", 24/RB["apollo11_coast_hours"], G["transit"]["nav_sighting"]["trigger_fraction_of_trip"][1], 0.001)
check("Midcourse 26.5 h as fraction of coast", RB["apollo11_midcourse_hours"]/RB["apollo11_coast_hours"], G["transit"]["midcourse_correction"]["trigger_fraction_of_trip"], 0.001)
check("Midcourse dv 20.9 ft/s in m/s", RB["apollo11_midcourse_dv_ft_s"]*0.3048, G["transit"]["midcourse_correction"]["nominal_dv_m_s"], 0.005)
check("Apollo 11 samples 47 lb in kg", RB["apollo11_sample_lb"]*0.45359237, 21.32, 0.01)
check("Apollo 17 EVA sum (h)", sum(RB["apollo17_eva_hours"]), RB["apollo17_eva_total_hours"], 0.01)
check("Apollo 17 EVA share of surface time", RB["apollo17_eva_total_hours"]/RB["apollo17_surface_hours"], 0.294, 0.001)
check("EVA window 75 s x 0.1 h/s (h)", G["surface"]["eva_window_s"]*ST["time_scale_h_per_game_s"], 7.5, 1e-9)
check("Open-loop easy pace seconds vs 75 s window (short by)", G["surface"]["eva_window_s"] - cap["open_loop"]/drain("easy"), 3.85, 0.01)
check("ECLSS Standard easy pace seconds", cap["eclss_standard"]/drain("easy"), 84.6, 0.05)
check("ECLSS Standard normal pace seconds", cap["eclss_standard"]/drain("normal"), 71.0, 0.05)
M = DE["mars"]
check("Mars day in Earth days", M["day_hours"]/24, 1.0275, 0.0001)
check("Mars cruise dose, 2 x Hohmann one way (mSv)", 2*planet_days("earth","mars")*M["radiation_cruise_msv_per_day"], 932.0, 1.0)
check("Mars surface dose, 500 d (mSv)", M["dra5_surface_days"]*M["radiation_surface_msv_per_day"], 335.0, 0.01)
check("Mars total dose (mSv)", 2*planet_days("earth","mars")*M["radiation_cruise_msv_per_day"]+M["dra5_surface_days"]*M["radiation_surface_msv_per_day"], 1267.0, 1.5)
check("MOXIE hours for 25 t O2 at 6 g/h", M["o2_for_4_crew_return_kg"]/(M["moxie_g_per_h"]/1000), 4166667, 1)
check("Moon min temp K to C", DE["moon"]["temp_k_min"]-273.15, -178.15, 0.01)
check("Relay shares sum (%)", sum(M["relay_percent_of_data"].values()), 100.0, 0.05)
check("2 h Venera survival in days", DE["venus"]["lander_survival_max_hours"]/24, 0.0833, 0.0001)

# ---- campaign mirror (scripts/campaign.gd): real transits and windows, 8-mission feasibility
import itertools
PR = load("probes")
CP = PR["campaign"]
def transit(pid): return planet_days("earth", PR_TARGET[pid])
PR_TARGET = {p["id"]: p["target"] for p in PR["probes"]}
for pid, want_days, tol in [("mars", 258.9, 1.0), ("mercury", 105.0, 1.5), ("venus", 146.0, 1.5),
                            ("jupiter", 998.0, 2.0), ("saturn", 2214.0, 5.0), ("uranus", 5870.0, 15.0), ("neptune", 11204.0, 25.0)]:
    check(f"campaign transit {pid} (d, Hohmann calc)", transit(pid), want_days, tol)
for pid, want in [("mercury", 115.9), ("venus", 583.9), ("mars", 779.9), ("jupiter", 398.9),
                  ("saturn", 378.1), ("uranus", 369.7), ("neptune", 367.5)]:
    check(f"campaign synodic {pid} (d)", synodic(B["earth"]["period_days"], B[PR_TARGET[pid]]["period_days"]), want, 0.5)
# Feasibility: launch at the start of a window (2 station days per launch), arrival after the real transit.
# The Moon crew mission runs first (9 days). The campaign must finish before deadline - epilogue.
def finish_day(order):
    day = 10.0; end = 0.0
    for pid in order:
        S = synodic(B["earth"]["period_days"], B[PR_TARGET[pid]]["period_days"])
        if (day - PR["epoch_day"]) % S >= CP["window_days"]:
            day = PR["epoch_day"] + math.ceil((day - PR["epoch_day"]) / S) * S
        arrive = day + math.ceil(transit(pid))
        end = max(end, arrive)
        day += CP["launch_station_days"]
    return end
ids = [p["id"] for p in PR["probes"]]
best = min((finish_day(o), o) for o in itertools.permutations(ids))
need = best[0] + CP["epilogue_days"]
print(f"campaign best finish day {best[0]:.0f} via {best[1]}; with epilogue {need:.0f} vs deadline {CP['deadline_days']}")
if need > CP["deadline_days"]:
    fails.append("campaign deadline too short for the best order")
    print("FAIL campaign: deadline too short for any order")
else:
    print("PASS campaign: deadline reachable with epilogue")

# ---- tag coverage: every top-level data key must be covered by a tag (exact path or prefix)
def covered(path, tags): return any(path == t or path.startswith(t + ".") for t in tags)
for name, cfgd in (("stamina", ST), ("physics", PH), ("farm", FA), ("destinations", DE), ("activities", AC), ("probes", PR)):
    tags = cfgd["tags"]
    def walk(obj, prefix):
        for k, v in obj.items():
            if k in ("tags", "note", "version"): continue
            p = f"{prefix}.{k}" if prefix else k
            if isinstance(v, dict) and not covered(p, tags): walk(v, p)
            elif not covered(p, tags):
                print(f"FAIL {name}: no tag for {p}"); fails.append(f"tag:{p}")
    walk(cfgd, "")
print("\nALL PASS" if not fails else f"\n{len(fails)} FAILED: {fails}")
sys.exit(1 if fails else 0)

