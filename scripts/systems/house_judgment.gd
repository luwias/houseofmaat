extends RefCounted
## A végső ítélet a Ház felett: a három lélek ügyén átívelő rejtély feloldása.
## A befejezést a játékos válaszai, a feltárt nyomok és a korábbi ítéletei döntik el.

const Cond = preload("res://scripts/systems/conditions.gd")


static func final_data() -> Dictionary:
	return GameData.mystery.get("final", {})


static func is_open(gs) -> bool:
	return gs.has_flag("mystery_open")


static func just_count(gs) -> int:
	var n := 0
	for h in gs.data.history:
		if str(h.get("category", "")).begins_with("just_"):
			n += 1
	return n


static func resolve(answers: Dictionary, gs) -> Dictionary:
	var fin := final_data()
	var ctx := {"answers": answers}
	var ending: Dictionary = {}
	for e in fin.get("endings", []):
		if Cond.check(e.get("conditions", true), gs, ctx):
			ending = e
			break
	if ending.is_empty():
		return {}
	var judged: int = gs.data.history.size()
	var just := just_count(gs)
	var epilogue := str(fin.get("epilogue_just", "")) if just * 2 >= judged else str(fin.get("epilogue_unjust", ""))
	var fates := []
	for h in gs.data.history:
		var soul := GameData.soul(str(h.case))
		fates.append({"name": soul.get("name", ""), "title": h.title, "category": h.category,
			"destination": GameData.destination_label(str(h.destination))})
	return {"ending": ending.id, "title": ending.title, "narrative": ending.narrative, "epilogue": epilogue,
		"effects": ending.get("effects", {}), "flags": ending.get("flags", []), "just": ending.get("just", false),
		"answers": answers, "fates": fates, "clues": gs.data.clues.size()}


static func apply(result: Dictionary, gs) -> void:
	gs.data["final_result"] = result
	for f in result.get("flags", []):
		gs.set_flag(str(f))
	gs.set_flag("final_judged")
	gs.apply_delta(result.get("effects", {}))
