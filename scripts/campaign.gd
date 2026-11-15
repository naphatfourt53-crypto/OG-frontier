class_name Campaign
extends RefCounted
# Campaign rules for the robotic probes and the deadline. Pure static functions: no scene,
# no hidden state. Transit and launch windows come from OrbitMath (physics.json, calc);
# costs and window length come from data/probes.json (game).

static var _cfg: Dictionary = {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var f := FileAccess.open("res://data/probes.json", FileAccess.READ)
		_cfg = JSON.parse_string(f.get_as_text())
	return _cfg

static func probe_ids() -> Array:
	var ids: Array = []
	for p in cfg()["probes"]:
		ids.append(String(p["id"]))
	return ids

static func probe(id: String) -> Dictionary:
	for p in cfg()["probes"]:
		if String(p["id"]) == id:
			return p
	return {}

static func deadline_days() -> float:
	return float(cfg()["campaign"]["deadline_days"])

static func epilogue_days() -> float:
	return float(cfg()["campaign"]["epilogue_days"])

static func epoch_day() -> float:
	return float(cfg()["epoch_day"])

# Days from Earth to the probe's target on a Hohmann transfer (calc, real orbit constants).
static func transit_days(id: String) -> float:
	return OrbitMath.planet_hohmann_days("earth", String(probe(id)["target"]))

# Days between two launch windows (calc). Earth to target synodic period.
static func synodic_days(id: String) -> float:
	var b: Dictionary = OrbitMath.cfg()["bodies"]
	return OrbitMath.synodic_days(float(b["earth"]["period_days"]), float(b[String(probe(id)["target"])]["period_days"]))

# A window is open for window_days at the start of every synodic cycle (game epoch).
static func window_open(id: String, day: float) -> bool:
	var s := synodic_days(id)
	var phase := fposmod(day - epoch_day(), s)
	return phase < float(cfg()["campaign"]["window_days"])

# Station-keeping: the share of the hold time the probe stayed inside its zone.
static func keeping_outcome(held_fraction: float) -> Dictionary:
	var ok := held_fraction >= float(cfg()["campaign"]["keeping_pass_pct"])
	var pct := int(round(held_fraction * 100.0))
	var text := "Held the orbit %d%% of the time: the probe is in place." % pct if ok \
		else "Held only %d%% of the time: the probe drifted out of its orbit and was lost." % pct
	return {"success": ok, "gas": 0, "text": text}

# Gas scoop: the player picks a depth. A roll in [0, 1) decides the pass. roll >= risk = safe.
static func scoop_outcome(depth_id: String, roll: float) -> Dictionary:
	for d in cfg()["gas_depths"]:
		if String(d["id"]) == depth_id:
			var ok := roll >= float(d["risk"])
			var text := "%s: %d gas units into the smelter." % [d["name"], int(d["gas_pts"])] if ok \
				else "%s: the probe lost attitude control in the deep layer and was lost." % d["name"]
			return {"success": ok, "gas": int(d["gas_pts"]) if ok else 0, "text": text}
	return {"success": false, "gas": 0, "text": "Unknown depth."}

# First day >= day on which the window is open.
static func next_window(id: String, day: float) -> float:
	if window_open(id, day):
		return day
	var s := synodic_days(id)
	var cycles: float = ceilf((day - epoch_day()) / s)
	return epoch_day() + cycles * s
