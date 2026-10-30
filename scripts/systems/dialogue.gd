extends RefCounted
## Párbeszéd- és kihallgatásmotor. A csomópontok, opciók, előfeltételek, hatások
## és kizáró döntéscsoportok mind az eset adataiban vannak.

const Cond = preload("res://scripts/systems/conditions.gd")


static func get_dialogue(case_data: Dictionary, did: String) -> Dictionary:
	return case_data.get("dialogues", {}).get(did, {})


static func node(case_data: Dictionary, did: String, nid: String) -> Dictionary:
	return get_dialogue(case_data, did).get("nodes", {}).get(nid, {})


static func option_key(did: String, nid: String, idx: int) -> String:
	return "%s.%s.%d" % [did, nid, idx]


static func options(case_data: Dictionary, did: String, nid: String, gs) -> Array:
	var out := []
	var opts: Array = node(case_data, did, nid).get("options", [])
	for i in opts.size():
		var opt: Dictionary = opts[i]
		var key := option_key(did, nid, i)
		if opt.has("requires") and not Cond.check(opt.requires, gs):
			continue
		if opt.has("hide_if") and Cond.check(opt.hide_if, gs):
			continue
		if opt.get("once", false) and gs.option_used(key):
			continue
		if opt.has("group") and gs.get_choice(str(opt.group)) != null:
			continue
		out.append({"index": i, "opt": opt, "key": key})
	return out


## Belépés egy csomópontba. A hatások csak az első látogatáskor futnak le.
static func enter(case_data: Dictionary, did: String, nid: String, gs) -> void:
	var first: bool = gs.visit_node("%s.%s" % [did, nid])
	if first:
		Cond.apply(node(case_data, did, nid).get("effects", []), gs, case_data.id)


static func choose(case_data: Dictionary, did: String, nid: String, idx: int, gs) -> String:
	var opts: Array = node(case_data, did, nid).get("options", [])
	if idx < 0 or idx >= opts.size():
		return "end"
	var opt: Dictionary = opts[idx]
	var key := option_key(did, nid, idx)
	var first: bool = gs.use_option(key)
	if opt.has("group"):
		gs.set_choice(str(opt.group), opt.get("value", key))
	if first:
		Cond.apply(opt.get("effects", []), gs, case_data.id)
	return str(opt.get("next", "end"))


## Van-e még fel nem fedezett beszédtéma a kezdő csomópontban?
static func has_new(case_data: Dictionary, did: String, gs) -> bool:
	if not gs.node_visited("%s.start" % did):
		return true
	for o in options(case_data, did, "start", gs):
		var opt: Dictionary = o.opt
		var nxt := str(opt.get("next", "end"))
		if nxt == "end" or nxt == "start":
			continue
		if not gs.node_visited("%s.%s" % [did, nxt]):
			return true
	return false
