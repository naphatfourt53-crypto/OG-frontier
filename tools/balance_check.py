#!/usr/bin/env python3
"""Balance check: mirrors scripts/game_state.gd in Python (no Godot needed).
Run:  python3 tools/balance_check.py
It answers: does the sample design win? do weak designs fail for the intended reason?
How many of the 2187 designs can win at all? Is the game too easy/hard?"""
import json, math, itertools, os
D = json.load(open(os.path.join(os.path.dirname(__file__), "..", "data", "game_data.json")))
C = D["constants"]; PARTS = D["parts"]; M = [m for m in D["missions"] if m["id"] == "moon"][0]
ORDER = ["cockpit", "engine", "tank", "life", "power", "storage", "comms"]

def analyze(design, fuel):
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
    need = {"o2": crew*days*r["o2"]*(1-life["o2_rec"]), "water": crew*days*r["water"]*(1-life["water_rec"]), "food": crew*days*r["food"]}
    left = PARTS[5]["options"][design["storage"]]["cap_kg"]; pack = {}
    for k in ("o2", "water", "food"):
        got = min(need[k]*C["supply_margin"], left); pack[k] = got; left -= got
    dry += sum(pack.values())
    tank = PARTS[2]["options"][design["tank"]]
    prop = tank["cap_t"]*1000*fuel
    cost += prop/1000*C["prop_cost_per_t"]
    isp = PARTS[1]["options"][design["engine"]]["isp"]
    return dict(dry=dry, prop=prop, cost=cost, gs=gs, go=go, use=use, pack=pack, need=need, isp=isp,
                shield=PARTS[0]["options"][design["cockpit"]]["shield"],
                total=dry+prop, ok_launch=(dry+prop <= C["mass_cap_kg"] and cost <= C["budget"]))

def simulate(design, fuel, evs, choices, explore=30):
    """evs: 3 event dicts; choices: 3 ints. Returns (success, reason)."""
    a = analyze(design, fuel); crew = C["crew"]; r = C["crew_day_kg"]
    life = PARTS[3]["options"][design["life"]]
    st = dict(a["pack"]); prop = a["prop"]; hull = 100.0; pm = 1.0
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
    def burn(leg):
        nonlocal prop
        ve = a["isp"]*C["g0"]; dv = leg["dv"]*(1+C["leg_margin"])*1000
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
        else: f = burn(L[step])
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

if __name__ == "__main__":
    rec = D["recommended"]; fuel = 0.65
    a = analyze(rec, fuel)
    ve = a["isp"]*C["g0"]
    dv = ve*math.log((a["dry"]+a["prop"])/a["dry"])/1000
    need = sum(l["dv"] for l in M["legs"])*(1+C["leg_margin"])
    print(f"SAMPLE DESIGN  mass {a['total']/1000:.1f} t  cost {a['cost']:.0f}/{C['budget']:.0f}  dv {dv:.2f} (need {need:.2f})  power net {a['gs']+a['go']-a['use']:+.1f} kW  launchable={a['ok_launch']}")
    b, r, why = evaluate(rec, fuel)
    print(f"  with smart choices wins in {b*100:.0f}% of event sets; with random choices {r*100:.0f}%;  failures: {why}")
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
