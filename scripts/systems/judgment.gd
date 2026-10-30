extends RefCounted
## Ítéletszámítás. Hat paraméter (Igazság, Bizonyíték, Szándék, Ártalom, Együttérzés,
## Felelősség) a feltárt bizonyítékokból, a rekonstrukcióból és a döntésekből.
## A befejezést az eset adatai döntik el feltételekkel – nincs egyszerű jó/rossz változó.

const Validator = preload("res://scripts/systems/story_validator.gd")
const Cond = preload("res://scripts/systems/conditions.gd")

const TRUTH_MULT := {"confirmed": 1.0, "supported": 0.85, "uncertain": 0.5, "contradicted": 0.15,
	"fabricated": 0.0, "incomplete": 0.0, "empty": 0.0}
const IMPL_MULT := {"confirmed": 1.0, "supported": 1.0, "uncertain": 0.6, "contradicted": 0.4,
	"fabricated": 0.3, "incomplete": 0.0, "empty": 0.0}
const PARAMS := ["truth", "evidence", "intent", "harm", "compassion", "responsibility"]


static func compute(case_data: Dictionary, gs) -> Dictionary:
	var slots := Validator.evaluate_board(case_data, gs)
	var scenes: Array = case_data.get("scenes", [])
	var truth := 0.0
	var complete := true
	for scene in scenes:
		var r: Dictionary = slots[scene.id]
		truth += float(r.truth) * float(TRUTH_MULT.get(r.state, 0.0))
		if r.state in ["empty", "incomplete"]:
			complete = false
	truth = truth / maxi(1, scenes.size())

	var req_total := 0
	var req_cov := 0.0
	var opt_total := 0
	var opt_cov := 0.0
	var missing_required := 0
	for ev in case_data.get("evidence", []):
		var known: bool = gs.has_evidence(ev.id) and not gs.is_corrupted(ev.id)
		var rel: float = gs.get_reliability(ev.id) / 100.0
		if ev.get("required", false):
			req_total += 1
			if known:
				req_cov += rel
			else:
				missing_required += 1
		else:
			opt_total += 1
			if known:
				opt_cov += rel
	var evidence: float = 100.0 * (0.8 * req_cov / maxi(1, req_total) + 0.2 * opt_cov / maxi(1, opt_total))

	var params: Dictionary = case_data.get("judgment", {}).get("base", {}).duplicate()
	for k in ["intent", "harm", "compassion", "responsibility"]:
		params[k] = float(params.get(k, 50))
	for scene in scenes:
		var r: Dictionary = slots[scene.id]
		var m: float = IMPL_MULT.get(r.state, 0.0)
		for k in r.implications:
			params[k] = float(params.get(k, 50)) + float(r.implications[k]) * m
	var mods: Dictionary = gs.case_params(case_data.id)
	for k in mods:
		params[k] = float(params.get(k, 50)) + float(mods[k])
	params["truth"] = truth
	params["evidence"] = evidence
	for k in PARAMS:
		params[k] = clampf(float(params.get(k, 0)), 0.0, 100.0)
	var balance: float = (params.harm + params.responsibility) - (params.intent + params.compassion)
	return {"params": params, "slots": slots, "complete": complete, "balance": balance,
		"missing_required": missing_required}


static func resolve(case_data: Dictionary, verdict: String, gs) -> Dictionary:
	var comp := compute(case_data, gs)
	var ctx := {"verdict": verdict, "params": comp.params, "slots": comp.slots}
	var ending: Dictionary = {}
	for e in case_data.get("endings", []):
		if Cond.check(e.get("conditions", true), gs, ctx):
			ending = e
			break
	if ending.is_empty():
		push_error("Nincs illeszkedő befejezés: %s / %s" % [case_data.id, verdict])
		return {}
	var category = ending.get("category", "unresolved")
	if category is Dictionary:
		category = category.get(verdict, "unresolved")

	var narrative: String = ending.get("narrative", "")
	for v in ending.get("variants", []):
		if Cond.check(v.get("when", true), gs, ctx):
			narrative += "\n\n" + str(v.text)

	var explain: Array = []
	for x in ending.get("explain", []):
		if Cond.check(x.get("when", true), gs, ctx):
			explain.append(str(x.text))
	if comp.missing_required > 0:
		explain.append(Loc.t("res_missing", [comp.missing_required]))
	for scene in case_data.get("scenes", []):
		var r: Dictionary = comp.slots[scene.id]
		if r.state == "contradicted":
			explain.append(Loc.t("res_kept_contradiction", [scene.title]))

	var reconstruction: Array = []
	for scene in case_data.get("scenes", []):
		var r: Dictionary = comp.slots[scene.id]
		reconstruction.append({"scene": scene.title, "scene_id": scene.id, "interp": r.interp,
			"title": r.title if r.title != "" else Loc.t("res_no_interp"), "state": r.state})

	return {"ending": ending.id, "title": ending.title, "category": str(category), "effects": ending.get("effects", []),
		"destination": ending.get("destination", ""), "narrative": narrative, "explain": explain,
		"params": comp.params, "reconstruction": reconstruction, "verdict": verdict}
