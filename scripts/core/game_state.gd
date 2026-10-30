extends Node
## A játék teljes, menthető állapota: templom-értékek, felfedezések, döntések,
## rekonstrukciók, ítéletek. Minden változás után automatikusan ment.

signal state_changed
signal temple_changed(old_values: Dictionary, new_values: Dictionary)
signal toast(text: String, kind: String)

const Cond = preload("res://scripts/systems/conditions.gd")
const Validator = preload("res://scripts/systems/story_validator.gd")

const SAVE_PATH := "user://houseofmaat_save.json"
const SAVE_VERSION := 1
const STATS := ["maat", "ankh", "duat"]

var data: Dictionary = {}
var autosave := true
var save_path := SAVE_PATH
var _dirty := false
var _quiet := 0


func _ready() -> void:
	reset_state()


func _process(delta: float) -> void:
	if data.has("playtime"):
		data.playtime = float(data.playtime) + delta
	if _dirty:
		_dirty = false
		_recheck_boards()
		if autosave:
			save_game()
		state_changed.emit()


func _mark() -> void:
	_dirty = true


## Azonnali feldolgozás (tesztekhez és képernyőváltáshoz).
func flush() -> void:
	if _dirty:
		_dirty = false
		_recheck_boards()
		if autosave:
			save_game()
		state_changed.emit()


func _toast(text: String, kind := "info") -> void:
	if _quiet == 0:
		toast.emit(text, kind)


# ------------------------------------------------------------ új játék / mentés
func reset_state() -> void:
	var init: Dictionary = GameData.temple.get("initial", {"maat": 75, "ankh": 62, "duat": 28})
	data = {
		"version": SAVE_VERSION,
		"temple": {"maat": float(init.maat), "ankh": float(init.ankh), "duat": float(init.duat)},
		"flags": {}, "evidence": {}, "reliability": {}, "inspected": {}, "revealed": {},
		"nodes": {}, "options": {}, "choices": {}, "lexicon": {}, "memories": {}, "clarified": {},
		"compared": {}, "clues": {}, "corrupted": {}, "cases": {}, "history": [],
		"active_case": "", "room": "hall", "consults": {}, "restored": {}, "playtime": 0.0,
		"seen_intro": false, "notes": {}
	}
	for e in GameData.temple.get("base_lexicon", []):
		data.lexicon[e.id] = true
	for cid in GameData.cases:
		_init_case(cid)


func new_game() -> void:
	reset_state()
	save_game()
	state_changed.emit()


func _init_case(cid: String) -> void:
	if not data.cases.has(cid):
		data.cases[cid] = {"status": "new", "board": {}, "params": {}, "verdict": "", "ending": "",
			"category": "", "last_states": {}}
	for ev in GameData.cases[cid].get("evidence", []):
		if ev.get("start", false):
			data.evidence[ev.id] = true


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_error("Nem sikerült menteni: %s" % save_path)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func load_game() -> bool:
	if not has_save():
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not parsed is Dictionary or int(parsed.get("version", 0)) != SAVE_VERSION:
		push_warning("A mentés nem olvasható vagy régi verziójú.")
		return false
	reset_state()
	for k in parsed:
		data[k] = parsed[k]
	for cid in GameData.cases:
		_init_case(cid)
	state_changed.emit()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


# ------------------------------------------------------------ zászlók és döntések
func has_flag(f: String) -> bool:
	return data.flags.has(f)


func set_flag(f: String) -> void:
	if not data.flags.has(f):
		data.flags[f] = true
		_mark()


func clear_flag(f: String) -> void:
	if data.flags.erase(f):
		_mark()


func get_choice(k: String):
	return data.choices.get(k, null)


func set_choice(k: String, v) -> void:
	data.choices[k] = v
	_mark()


func node_visited(key: String) -> bool:
	return data.nodes.has(key)


## true-t ad vissza, ha ez az első látogatás.
func visit_node(key: String) -> bool:
	if data.nodes.has(key):
		return false
	data.nodes[key] = true
	_mark()
	return true


func option_used(key: String) -> bool:
	return data.options.has(key)


func use_option(key: String) -> bool:
	if data.options.has(key):
		return false
	data.options[key] = true
	_mark()
	return true


# ------------------------------------------------------------ bizonyítékok
func has_evidence(eid: String) -> bool:
	return data.evidence.has(eid)


func unlock_evidence(eid: String) -> void:
	if has_evidence(eid):
		return
	var ev := GameData.evidence(eid)
	if ev.is_empty():
		push_warning("Ismeretlen bizonyíték: %s" % eid)
		return
	data.evidence[eid] = true
	_toast(Loc.t("toast_new_evidence", [eid, ev.title]), "evidence")
	_maybe_corrupt(eid)
	_mark()


func is_inspected(eid: String) -> bool:
	return data.inspected.has(eid)


func mark_inspected(eid: String) -> void:
	if data.inspected.has(eid):
		return
	data.inspected[eid] = true
	var ev := GameData.evidence(eid)
	if ev.has("param"):
		for p in ev.param:
			add_param(str(ev.get("_case", "")), str(p), float(ev.param[p]))
	_mark()


func is_revealed(key: String) -> bool:
	return data.revealed.has(key)


func reveal(eid: String, action_id: String) -> bool:
	var key := "%s.%s" % [eid, action_id]
	if data.revealed.has(key):
		return false
	data.revealed[key] = true
	var ev := GameData.evidence(eid)
	for a in ev.get("inspect", []):
		if a.id == action_id:
			Cond.apply(a.get("effects", []), self, str(ev.get("_case", "")))
	_mark()
	return true


func get_reliability(eid: String) -> float:
	if data.reliability.has(eid):
		return float(data.reliability[eid])
	return float(GameData.evidence(eid).get("reliability", 50))


func set_reliability(eid: String, v: float) -> void:
	var old := get_reliability(eid)
	data.reliability[eid] = clampf(v, 0.0, 100.0)
	if has_evidence(eid) and absf(old - v) > 0.5:
		_toast(Loc.t("toast_reliability", [GameData.evidence(eid).get("title", eid), int(old), int(v)]), "reliability")
	_mark()


func evidence_text(eid: String) -> String:
	var ev := GameData.evidence(eid)
	for v in ev.get("variants", []):
		if Cond.check(v.get("when", false), self):
			return str(v.text)
	return str(ev.get("text", ""))


func is_corrupted(eid: String) -> bool:
	return data.corrupted.has(eid)


func purify(eid: String) -> void:
	if data.corrupted.erase(eid):
		_toast(Loc.t("toast_purified", [GameData.evidence(eid).get("title", eid)]), "good")
		_mark()


func _maybe_corrupt(eid: String) -> void:
	var th := float(GameData.temple.get("corruption_duat", 60))
	var ev := GameData.evidence(eid)
	if get_stat("duat") >= th and not ev.get("start", false) and randf() < 0.35:
		data.corrupted[eid] = true
		_toast(Loc.t("toast_corrupted", [ev.get("title", eid)]), "bad")


func corrupt_random(case_id: String) -> void:
	var pool := []
	for ev in GameData.get_case(case_id).get("evidence", []):
		if has_evidence(ev.id) and not is_corrupted(ev.id) and not ev.get("start", false):
			pool.append(ev.id)
	if pool.is_empty():
		return
	var eid: String = pool[randi() % pool.size()]
	data.corrupted[eid] = true
	_toast(Loc.t("toast_corrupted", [GameData.evidence(eid).get("title", eid)]), "bad")
	_mark()


# ------------------------------------------------------------ összevetés
static func pair_key(a: String, b: String) -> String:
	return "%s+%s" % [a, b] if a < b else "%s+%s" % [b, a]


func was_compared(key: String) -> bool:
	var parts := key.split("+")
	if parts.size() == 2:
		return data.compared.has(pair_key(parts[0], parts[1]))
	return false


## Két bizonyíték összevetése. Visszaadja az eredmény szövegét és hogy új felfedezés volt-e.
func compare_evidence(case_id: String, a: String, b: String) -> Dictionary:
	var key := pair_key(a, b)
	var case_data := GameData.get_case(case_id)
	if is_corrupted(a) or is_corrupted(b):
		return {"text": Loc.t("cmp_corrupted"), "found": false}
	for c in case_data.get("comparisons", []):
		var p: Array = c.pair
		if pair_key(str(p[0]), str(p[1])) != key:
			continue
		if c.has("requires") and not Cond.check(c.requires, self):
			continue
		var first: bool = not data.compared.has(key + "#" + str(case_data.comparisons.find(c)))
		data.compared[key] = true
		data.compared[key + "#" + str(case_data.comparisons.find(c))] = true
		if first:
			Cond.apply(c.get("effects", []), self, case_id)
		_mark()
		return {"text": str(c.text), "found": true, "first": first}
	data.compared[key] = true
	_mark()
	return {"text": Loc.t("cmp_nothing"), "found": false}


# ------------------------------------------------------------ jelek, emlékek, nyomok
func knows_glyph(id: String) -> bool:
	return data.lexicon.has(id)


func learn_glyph(id: String) -> void:
	if data.lexicon.has(id):
		return
	data.lexicon[id] = true
	var e: Dictionary = GameData.lexicon.get(id, {})
	_toast(Loc.t("toast_glyph", [e.get("glyph", "?"), e.get("meaning", id)]), "glyph")
	_mark()


func memory_unlocked(mid: String) -> bool:
	return data.memories.has(mid)


func unlock_memory(mid: String) -> void:
	if data.memories.has(mid):
		return
	data.memories[mid] = true
	set_flag("any_memory")
	var title := mid
	for c in GameData.cases.values():
		if c._memories.has(mid):
			title = c._memories[mid].title
	_toast(Loc.t("toast_memory", [title]), "memory")
	_mark()


func is_clarified(key: String) -> bool:
	return data.clarified.has(key)


func clarify(mid: String, idx: int, case_id: String) -> void:
	var key := "%s.%d" % [mid, idx]
	if data.clarified.has(key):
		return
	data.clarified[key] = true
	var m: Dictionary = GameData.get_case(case_id).get("_memories", {}).get(mid, {})
	var frags: Array = m.get("fragments", [])
	if idx < frags.size():
		Cond.apply(frags[idx].get("effects", []), self, case_id)
	_mark()


func has_clue(id: String) -> bool:
	return data.clues.has(id)


func add_clue(id: String) -> void:
	if data.clues.has(id):
		return
	data.clues[id] = true
	_toast(Loc.t("toast_clue", [GameData.clue(id).get("title", id)]), "clue")
	_mark()


# ------------------------------------------------------------ kártyák, kirakó
func card_available(card_id: String) -> bool:
	var card := GameData.card(card_id)
	if card.is_empty():
		return false
	match str(card.category):
		"evidence":
			return has_evidence(card_id)
		"memory":
			return memory_unlocked(str(card.memory))
	return Cond.check(card.get("unlock", true), self)


# ------------------------------------------------------------ jegyzetek
func get_note(key: String) -> String:
	return str(data.get("notes", {}).get(key, ""))


func set_note(key: String, text: String) -> void:
	if not data.has("notes"):
		data["notes"] = {}
	if str(data.notes.get(key, "")) == text:
		return
	data.notes[key] = text
	_mark()


## Hányszor van már lehelyezve a kártya a storyboardon.
func card_used(cid: String, card_id: String) -> int:
	var n := 0
	for sid in board(cid):
		if card_id in board(cid)[sid]:
			n += 1
	return n


## Hány példány maradt még a tálcán.
func card_remaining(cid: String, card_id: String) -> int:
	return int(GameData.card(card_id).get("copies", 1)) - card_used(cid, card_id)


func board(cid: String) -> Dictionary:
	if not data.cases.has(cid):
		return {}
	return data.cases[cid].board


func set_board_slot(cid: String, slot_id: String, cards: Array) -> Dictionary:
	data.cases[cid].board[slot_id] = cards.duplicate()
	var case_data := GameData.get_case(cid)
	var res := Validator.validate(case_data, case_data._scenes[slot_id], cards, self)
	data.cases[cid].last_states[slot_id] = res.state
	_mark()
	return res


func _recheck_boards() -> void:
	for cid in data.cases:
		var cs: Dictionary = data.cases[cid]
		if cs.status != "in_progress":
			continue
		var case_data := GameData.get_case(cid)
		var results := Validator.evaluate_board(case_data, self)
		for sid in results:
			var new_state: String = results[sid].state
			var old = cs.last_states.get(sid)
			if old != null and str(old) != new_state and str(old) != "empty":
				_toast(Loc.t("toast_interp_changed", [case_data._scenes[sid].title, Loc.t("state_" + str(old)),
					Loc.t("state_" + new_state)]), "interp")
			cs.last_states[sid] = new_state


# ------------------------------------------------------------ esetek
func case_state(cid: String) -> Dictionary:
	return data.cases.get(cid, {})


func case_done(cid: String) -> bool:
	return data.cases.has(cid) and data.cases[cid].status == "judged"


func any_case_done() -> bool:
	for cid in data.cases:
		if data.cases[cid].status == "judged":
			return true
	return false


func start_case(cid: String) -> void:
	data.active_case = cid
	var cs: Dictionary = data.cases[cid]
	if cs.status == "new":
		cs.status = "in_progress"
		if get_stat("duat") >= float(GameData.temple.get("corruption_duat", 60)):
			corrupt_random(cid)
	_mark()


func case_params(cid: String) -> Dictionary:
	return data.cases.get(cid, {}).get("params", {})


func add_param(cid: String, p: String, v: float) -> void:
	if cid == "" or not data.cases.has(cid):
		return
	var params: Dictionary = data.cases[cid].params
	params[p] = float(params.get(p, 0.0)) + v
	_mark()


func record_judgment(cid: String, result: Dictionary) -> void:
	var cs: Dictionary = data.cases[cid]
	cs.status = "judged"
	cs.verdict = result.verdict
	cs.ending = result.ending
	cs.category = result.category
	cs.result = result
	var before: Dictionary = data.temple.duplicate()
	apply_outcome(result.category)
	data.history.append({"case": cid, "ending": result.ending, "title": result.title, "category": result.category,
		"verdict": result.verdict, "destination": result.destination, "before": before, "after": data.temple.duplicate()})
	set_flag("first_judgment")
	Cond.apply(GameData.get_case(cid).get("on_judged", []), self, cid)
	if data.active_case == cid:
		data.active_case = ""
	_mark()


# ------------------------------------------------------------ templom
func get_stat(s: String) -> float:
	return float(data.temple.get(s, 0.0))


func temple_values() -> Dictionary:
	return data.temple.duplicate()


func set_temple(values: Dictionary) -> void:
	var old := temple_values()
	for k in values:
		data.temple[k] = clampf(float(values[k]), 0.0, 100.0)
	temple_changed.emit(old, temple_values())
	_mark()


func apply_outcome(category: String) -> Dictionary:
	var eff: Dictionary = GameData.category(category).get("effects", {})
	var old := temple_values()
	var th := float(GameData.temple.get("corruption_duat", 60))
	for k in eff:
		data.temple[k] = clampf(get_stat(k) + float(eff[k]), 0.0, 100.0)
	if old.duat < th and get_stat("duat") >= th:
		for cid in data.cases:
			if data.cases[cid].status == "in_progress":
				corrupt_random(cid)
	temple_changed.emit(old, temple_values())
	_mark()
	return eff


func room_status(rid: String) -> Dictionary:
	var r := GameData.room(rid)
	if r.is_empty():
		return {"open": false, "reason": ""}
	if not Cond.check(r.get("unlock", true), self):
		return {"open": false, "reason": str(r.get("hint", "")), "locked": true}
	if r.has("close") and Cond.check(r.close, self):
		return {"open": false, "reason": str(r.get("close_hint", "")), "closed": true}
	return {"open": true, "reason": ""}


func room_state_text(rid: String) -> String:
	for s in GameData.room(rid).get("states", []):
		if Cond.check(s.get("when", true), self):
			return str(s.text)
	return ""


func consult_key(cid: String, deity: String) -> String:
	return "%s.%s" % [cid, deity]
