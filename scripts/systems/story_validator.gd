extends RefCounted
## Jelenet-validáció: a lerakott kártyákból kikeresi a legjobban illeszkedő értelmezést,
## és a felfedezett bizonyítékok alapján állapotot ad neki.
##
## Állapotok: confirmed (megerősített), supported (alátámasztott), uncertain (bizonytalan),
## contradicted (ellentmondásos), fabricated (kitalált), incomplete (hiányos), empty (üres).
## A validátor soha nem használ fel olyan bizonyítékot, amelyet a játékos még nem tárt fel.

const MEMORY_WEIGHT := 70.0
const PLACED_BONUS := 1.5
const SUPPORT_THRESHOLD := 60.0
const CONTRADICT_MIN_RELIABILITY := 40.0
const MAX_CARDS := 5

const STATE_RANK := {"empty": 0, "incomplete": 1, "fabricated": 2, "contradicted": 3, "uncertain": 4,
	"supported": 5, "confirmed": 6}


static func weight_of(id: String, gs) -> float:
	var card: Dictionary = GameData.card(id)
	if card.is_empty():
		return 0.0
	match str(card.category):
		"memory":
			return MEMORY_WEIGHT if gs.memory_unlocked(str(card.memory)) else 0.0
		"evidence":
			if not gs.has_evidence(id) or gs.is_corrupted(id):
				return 0.0
			return gs.get_reliability(id)
	return 0.0


static func validate(case_data: Dictionary, scene: Dictionary, cards: Array, gs) -> Dictionary:
	var res := {"state": "empty", "interp": "", "title": "", "narrative": "", "support": [], "contradict": [],
		"extras": [], "notes": [], "truth": 0.0, "implications": {}, "weight": 0.0}
	if cards.is_empty():
		return res
	if cards.size() < int(scene.get("min_cards", 2)):
		res.state = "incomplete"
		res.notes.append(Loc.t("sb_note_incomplete"))
		return res

	var best: Dictionary = {}
	var best_score := -1
	for interp in scene.get("interpretations", []):
		var ok := true
		for r in interp.get("required", []):
			if not r in cards:
				ok = false
				break
		if not ok:
			continue
		var score: int = interp.required.size() * 10
		for o in interp.get("optional", []):
			if o in cards:
				score += 1
		if score > best_score:
			best_score = score
			best = interp

	if best.is_empty():
		if _linked(case_data, cards, gs):
			res.state = "uncertain"
			res.notes.append(Loc.t("sb_note_linked"))
		else:
			res.state = "fabricated"
			res.notes.append(Loc.t("sb_note_unlinked"))
		return res

	res.interp = best.id
	res.title = best.title
	res.narrative = best.get("narrative", "")
	res.truth = float(best.get("truth", 0))
	res.implications = best.get("implications", {})

	var allowed: Array = best.get("required", []) + best.get("optional", [])
	for c in cards:
		if not c in allowed:
			res.extras.append(c)

	var w := 0.0
	for s in best.get("support", []):
		var sw := weight_of(str(s), gs)
		if sw > 0.0:
			if s in cards:
				sw *= PLACED_BONUS
			w += sw
			res.support.append(s)
	for k in best.get("contradict", []):
		if weight_of(str(k), gs) >= CONTRADICT_MIN_RELIABILITY:
			res.contradict.append(k)
	res.weight = w

	var state := "fabricated"
	if not res.contradict.is_empty():
		state = "contradicted"
	elif w >= float(best.get("confirm", 150)):
		state = "confirmed"
	elif w >= float(best.get("support_min", SUPPORT_THRESHOLD)):
		state = "supported"
	elif w > 0.0:
		state = "uncertain"
	# Gyenge igazságtartalmú (félrevezető) értelmezés legfeljebb „alátámasztott” lehet:
	# a félrevezető bizonyíték támogathat valamit, de nem teheti megerősített igazsággá.
	if state == "confirmed" and res.truth < 50.0:
		state = "supported"
	if not res.extras.is_empty() and state in ["confirmed", "supported"]:
		state = "uncertain"
		res.notes.append(Loc.t("sb_note_extras"))
	if state == "fabricated":
		res.notes.append(Loc.t("sb_note_nosupport"))
	res.state = state
	return res


static func _linked(case_data: Dictionary, cards: Array, gs) -> bool:
	for ev in case_data.get("evidence", []):
		if not gs.has_evidence(ev.id) or gs.is_corrupted(ev.id):
			continue
		var assoc: Array = ev.get("associated", [])
		var hits := 0
		for c in cards:
			if c in assoc or c == ev.id:
				hits += 1
		if hits >= 2:
			return true
	return false


static func evaluate_board(case_data: Dictionary, gs) -> Dictionary:
	var out := {}
	var board: Dictionary = gs.board(case_data.id)
	for scene in case_data.get("scenes", []):
		out[scene.id] = validate(case_data, scene, board.get(scene.id, []), gs)
	return out
