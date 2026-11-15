#!/usr/bin/env python3
"""Balance check: mirrors scripts/game_state.gd in Python (no Godot needed).
Run:  python3 tools/balance_check.py
It answers: does the sample design win? do weak designs fail for the intended reason?
How many of the 2187 designs can win at all? Is the game too easy/hard?"""
import json, math, itertools, os, sys
D = json.load(open(os.path.join(os.path.dirname(__file__), "..", "data", "game_data.json"), encoding="utf-8"))
C = D["constants"]; PARTS = D["parts"]; M = [m for m in D["missions"] if m["id"] == "moon"][0]
ORDER = ["cockpit", "engine", "tank", "life", "power", "storage", "comms"]

def analyze(design, fuel, food_store=0.0):
    dry = cost = gs = go = use = 0.0
    for p in PARTS:
        o = p["options"][design[p["id"]]]
        dry += o["mass"]; cost += o["cost"]
        if o["power"] >= 0:
            if o.get("solar"): gs += o["power"]
            else: go += o["power"]
        else: use -= o["power"]
    days = sum(M["days"].values()); crew = C["crew"]; r = C["crew_day_kg"]
    life = PARTS[3]["options"][design["life"]]
    food_raw = crew*days*r["food"]
    food_used = min(food_store, food_raw)
    need = {"o2": crew*days*r["o2"]*(1-life["o2_rec"]), "water": crew*days*r["water"]*(1-life["water_rec"]), "food": food_raw - food_used}
    left = PARTS[5]["options"][design["storage"]]["cap_kg"]; pack = {}
    for k in ("o2", "water", "food"):
        got = min(need[k]*C["supply_margin"], left); pack[k] = got; left -= got
    dry += sum(pack.values())
    tank = PARTS[2]["options"][design["tank"]]
    prop = tank["cap_t"]*1000*fuel
    cost += prop/1000*C["prop_cost_per_t"]
    isp = PARTS[1]["options"][design["engine"]]["isp"]
    ve = isp*C["g0"]
    dv = ve*math.log((dry+prop)/dry)/1000
    dv_need = sum(l["dv"] for l in M["legs"])*(1+C["leg_margin"])
    return dict(dry=dry, prop=prop, cost=cost, gs=gs, go=go, use=use, pack=pack, need=need, isp=isp,
                food_used=food_used,
                shield=PARTS[0]["options"][design["cockpit"]]["shield"],
                total=dry+prop, ok_launch=(dry+prop <= C["mass_cap_kg"] and cost <= C["budget"]),
                dv=dv, dv_need=dv_need, net=gs+go-use, comm_q=PARTS[6]["options"][design["comms"]]["quality"],
                budget=C["budget"], mass_cap=C["mass_cap_kg"], total_need=sum(need.values()),
                cap=PARTS[5]["options"][design["storage"]]["cap_kg"])

def simulate(design, fuel, evs, choices, explore=80, food_store=0.0, dv_penalty=0.0):
    """evs: 3 event dicts; choices: 3 ints. Returns (success, reason).
    explore = science points from the EVA. Shown on the report and added to Data,
    but it never changes survival, so the default is just the expected value of a good walk.
    food_store is ISS greenhouse food: it replaces packed food and rides in the galley.
    dv_penalty (m/s) is the T17 midcourse-burn shortfall carried into the next leg burn."""
    a = analyze(design, fuel, food_store); crew = C["crew"]; r = C["crew_day_kg"]
    life = PARTS[3]["options"][design["life"]]
    st = dict(a["pack"]); st["food"] += a["food_used"]; prop = a["prop"]; hull = 100.0; pm = 1.0
    state = {"pm": 1.0}
    def consume(days):
        nonlocal st
        st["o2"] -= crew*days*r["o2"]*(1-life["o2_rec"])
        st["water"] -= crew*days*r["water"]*(1-life["water_rec"])
        st["food"] -= crew*days*r["food"]
        net = a["gs"]*state["pm"] + a["go"] - a["use"]; state["pm"] = 1.0
        if net < 0: return "Power Failure"
        if st["o2"] < 0: return "Oxygen Depletion"
        if st["food"] < 0 or st["water"] < 0: return "Starvation"
    def burn(leg, penalty=0.0):
        nonlocal prop
        ve = a["isp"]*C["g0"]; dv = leg["dv"]*(1+C["leg_margin"])*1000 + penalty
        mi = a["dry"] + prop; need = mi*(1-math.exp(-dv/ve))
        if need > prop: return leg["fail"]
        prop -= need
    def event(i):
        nonlocal hull, prop
        fx = evs[i]["choices"][choices[i]]["fx"]; res = None
        if "days" in fx: res = consume(fx["days"])
        if "supply_pct" in fx:
            for k in st: st[k] *= 1+fx["supply_pct"]
        if "water_kg" in fx: st["water"] += fx["water_kg"]
        if "prop_pct" in fx: prop *= 1+fx["prop_pct"]
        if "hull" in fx: hull += fx["hull"]
        if "rad_hull" in fx: hull -= fx["rad_hull"]*(1-a["shield"])
        if "power_mult" in fx: state["pm"] = fx["power_mult"]
        if res: return res
        if hull <= 0: return "Ship Destruction"
    d = M["days"]; L = {l["id"]: l for l in M["legs"]}
    for step in ["coast_out","event","loi","landing","land_day","explore","event","surface","return","coast_back","event"]:
        if step == "coast_out": f = consume(d["transit_out"])
        elif step == "land_day": f = consume(d["landing"])
        elif step == "surface": f = consume(d["surface"])
        elif step == "coast_back": f = consume(d["transit_back"])
        elif step == "explore": f = None
        elif step == "event":
            f = event(simulate.k); simulate.k += 1
        else: f = burn(L[step], dv_penalty if step == "loi" else 0.0)
        if f: simulate.k = 0; return False, f
    simulate.k = 0
    return True, ""
simulate.k = 0

space = [e for e in D["events"] if e["slot"] == "space"]; surf = [e for e in D["events"] if e["slot"] == "surface"]
def combos():
    for e1 in space:
        for e2 in surf:
            for e3 in space:
                if e3["id"] != e1["id"]: yield (e1, e2, e3)

def evaluate(design, fuel):
    """returns (best_case_wins_all_event_sets?, share of outcomes that succeed with optimal choices, share with random choices, failure reasons)"""
    total = best_ok = rand_ok = 0; reasons = {}
    for evs in combos():
        total += 1; outs = []
        for ch in itertools.product((0, 1), repeat=3):
            ok, why = simulate(design, fuel, evs, ch); outs.append(ok)
            if not ok: reasons[why] = reasons.get(why, 0) + 1
        best_ok += any(outs); rand_ok += sum(outs)/8
    return best_ok/total, rand_ok/total, reasons

GOLDEN_CASES = [
    ("sample_065", D["recommended"], 0.65),
    ("sample_full_tank", D["recommended"], 1.0),
    ("open_loop_small_locker", {**D["recommended"], "life": 0, "storage": 0}, 0.65),
    ("heavy_cabin_small_solar", {**D["recommended"], "cockpit": 2, "life": 2, "power": 0}, 0.65),
    ("light_cheap", {"cockpit": 0, "engine": 0, "tank": 0, "life": 0,
                     "power": 0, "storage": 0, "comms": 0}, 0.5),
]

def golden_cases():
    for name, design, fuel in GOLDEN_CASES:
        a = analyze(design, fuel)
        exp = dict(dry_kg=a["dry"], prop_kg=a["prop"], total_kg=a["total"], mass_cap_kg=a["mass_cap"],
                   cost=a["cost"], budget=a["budget"], net=a["net"], isp=a["isp"],
                   dv=a["dv"], dv_need=a["dv_need"], comm_q=a["comm_q"], shield=a["shield"], cap=a["cap"])
        for k in ("o2", "water", "food"):
            exp[k + "_need"] = a["need"][k]
            exp[k + "_pack"] = a["pack"][k]
        yield {"name": name, "design": design, "fuel": fuel, "expect": exp}

if __name__ == "__main__":
    if "--emit-golden" in sys.argv:
        out = os.path.join(os.path.dirname(__file__), "..", "tests", "golden.json")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        payload = {"note": "Generated by tools/balance_check.py --emit-golden. Do not edit by hand.",
                   "mission": "moon", "tol": 0.01, "cases": list(golden_cases())}
        with open(out, "w", encoding="utf-8") as f:
            json.dump(payload, f, indent=2)
        # Keep stdout ASCII: the Windows console here is cp932 and would crash on Thai paths.
        print("golden written: tests/golden.json (%d cases)" % len(payload["cases"]))
        raise SystemExit(0)

    rec = D["recommended"]; fuel = 0.65
    moon = D.get("moon_resources", {})
    pool = sum(r["count"] * r["pts"] for r in moon.values())
    print(f"EVA sample pool: {pool} pts if you collect everything; a good walk (about half) = {pool*0.5:.0f} pts")
    print()
    a = analyze(rec, fuel)
    ve = a["isp"]*C["g0"]
    dv = ve*math.log((a["dry"]+a["prop"])/a["dry"])/1000
    need = sum(l["dv"] for l in M["legs"])*(1+C["leg_margin"])
    print(f"SAMPLE DESIGN  mass {a['total']/1000:.1f} t  cost {a['cost']:.0f}/{C['budget']:.0f}  dv {dv:.2f} (need {need:.2f})  power net {a['gs']+a['go']-a['use']:+.1f} kW  launchable={a['ok_launch']}")
    b, r, why = evaluate(rec, fuel)
    print(f"  with smart choices wins in {b*100:.0f}% of event sets; with random choices {r*100:.0f}%;  failures: {why}")
    print()
    # T17 worst case: skipped nav + skipped midcourse burn -> 12.37 m/s penalty on leg:loi.
    # The sample design must still win every easy event set with this penalty.
    worst_penalty = 6.37 + 6.0
    ok_worst, why_worst = simulate(rec, fuel, (space[0], surf[0], space[1]), (0, 0, 0), dv_penalty=worst_penalty)
    print(f"T17 worst-case burn penalty {worst_penalty:.2f} m/s on loi: sample design {'still wins' if ok_worst else 'FAILS (' + why_worst + ')'}")
    print()
    # intended-failure demos
    demos = {
      "Too little fuel (Stranded/Ship Destruction)": (rec, 0.25),
      "Open-loop life support + small locker (Starvation)": ({**rec, "life": 0, "storage": 0}, 0.65),
      "Big power-hungry cabin on small solar (Power Failure)": ({**rec, "cockpit": 2, "life": 2, "power": 0}, 0.65),
      "Thin hull + risky choices (Ship Destruction)": ({**rec, "cockpit": 0}, 0.65),
    }
    for name, (d, f) in demos.items():
        b, r, why = evaluate(d, f)
        print(f"{name}: smart-win {b*100:.0f}%, random-win {r*100:.0f}%  failures {why}")
    print()
    # whole design space
    n = wins = launchable = robust = 0
    for combo in itertools.product(range(3), repeat=7):
        d = dict(zip(ORDER, combo))
        for fuel in (0.5, 0.65, 0.8, 1.0):
            a = analyze(d, fuel)
            if not a["ok_launch"]: continue
            launchable += 1
            e1 = space[0]; e2 = surf[0]; e3 = space[1]
            ok, _ = simulate(d, fuel, (e1, e2, e3), (0, 0, 0))
            if ok: wins += 1
    print(f"Design space (2187 designs x 4 fuel levels): {launchable} launchable, {wins} win an easy event set ({wins/launchable*100:.1f}% of launchable)")
