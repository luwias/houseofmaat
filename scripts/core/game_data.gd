extends Node
## Az összes adatfájl betöltése és indexelése. A narratíva kizárólag adatból jön,
## a felület csak megjeleníti.

var souls: Array = []
var cases: Dictionary = {}
var temple: Dictionary = {}
var rooms: Array = []
var mystery: Dictionary = {}
var evidence_index: Dictionary = {}
var card_index: Dictionary = {}
var lexicon: Dictionary = {}
var clue_index: Dictionary = {}
var room_index: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	souls = _read("souls.json").get("souls", [])
	temple = _read("temple.json")
	rooms = _read("rooms.json").get("rooms", [])
	mystery = _read("mystery.json")
	cases.clear()
	evidence_index.clear()
	card_index.clear()
	lexicon.clear()
	clue_index.clear()
	room_index.clear()
	for e in temple.get("base_lexicon", []):
		lexicon[e.id] = e
	for c in mystery.get("clues", []):
		clue_index[c.id] = c
	for r in rooms:
		room_index[r.id] = r
	for s in souls:
		if s.get("playable", false):
			var c := _read("cases/%s.json" % s.id)
			if c.is_empty():
				continue
			_index_case(c)
			cases[s.id] = c


func _index_case(c: Dictionary) -> void:
	var cid: String = c.id
	var ev_map := {}
	var card_map := {}
	var scene_map := {}
	var mem_map := {}
	for ev in c.get("evidence", []):
		ev["_case"] = cid
		ev_map[ev.id] = ev
		evidence_index[ev.id] = ev
		var card := {"id": ev.id, "category": "evidence", "title": ev.title, "glyph": _evidence_glyph(ev),
			"desc": ev.description, "_case": cid}
		card_map[ev.id] = card
		card_index[ev.id] = card
	for card in c.get("cards", []):
		card["_case"] = cid
		card_map[card.id] = card
		card_index[card.id] = card
	for m in c.get("memories", []):
		m["_case"] = cid
		mem_map[m.id] = m
		var mc := {"id": m.card, "category": "memory", "title": m.title, "glyph": m.get("glyph", "𓂀"),
			"desc": Loc.t("card_memory_desc"), "memory": m.id, "_case": cid}
		card_map[m.card] = mc
		card_index[m.card] = mc
	for sc in c.get("scenes", []):
		scene_map[sc.id] = sc
	for e in c.get("lexicon", []):
		lexicon[e.id] = e
	c["_evidence"] = ev_map
	c["_cards"] = card_map
	c["_scenes"] = scene_map
	c["_memories"] = mem_map


func _evidence_glyph(ev: Dictionary) -> String:
	match str(ev.get("type", "")):
		"document":
			return "𓏞"
		"image":
			return "𓁹"
		"object":
			return "𓍼"
		"testimony":
			return "𓂋"
		"record":
			return "𓏛"
	return "𓏞"


func _read(rel: String) -> Dictionary:
	var path := Loc.data_path(rel)
	if not FileAccess.file_exists(path):
		push_error("Hiányzó adatfájl: %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Hibás JSON: %s" % path)
		return {}
	return parsed


# ------------------------------------------------------------ lekérdezők
func get_case(cid: String) -> Dictionary:
	return cases.get(cid, {})


func evidence(eid: String) -> Dictionary:
	return evidence_index.get(eid, {})


func card(card_id: String) -> Dictionary:
	return card_index.get(card_id, {})


func soul(sid: String) -> Dictionary:
	for s in souls:
		if s.id == sid:
			return s
	return {}


func room(rid: String) -> Dictionary:
	return room_index.get(rid, {})


func category(cat: String) -> Dictionary:
	return temple.get("categories", {}).get(cat, {})


func verdict(vid: String) -> Dictionary:
	for v in temple.get("verdicts", []):
		if v.id == vid:
			return v
	return {}


func destination_label(dest: String) -> String:
	return str(temple.get("destinations", {}).get(dest, dest))


func clue(cl_id: String) -> Dictionary:
	return clue_index.get(cl_id, {})
