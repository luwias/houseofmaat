extends "res://scripts/ui/widgets/overlay.gd"
## A Hieroglifák Kamrája: a megtanult jelek szótára és a titkosírások fordítása.

const Cond = preload("res://scripts/systems/conditions.gd")

var lex_box: Control
var puzzle_box: VBoxContainer
var selections := {}
var feedback := {}


func build() -> void:
	var p := centered(Vector2(1260, 760))
	var v := UI.vbox(12)
	p.add_child(v)
	v.add_child(header(GameData.room("hieroglyphs").name, "𓋹", GameData.room("hieroglyphs").purpose))
	v.add_child(UI.separator())
	var h := UI.hbox(18)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	var left := UI.vbox(10)
	left.custom_minimum_size.x = 380
	left.add_child(UI.title(Loc.t("hg_lexicon"), 20, T.GOLD))
	lex_box = UI.vbox(6)
	left.add_child(UI.scroll(lex_box))
	h.add_child(left)
	var right := UI.papyrus(26)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	puzzle_box = UI.vbox(14)
	right.add_child(UI.scroll(puzzle_box))
	h.add_child(right)
	refresh()


func refresh() -> void:
	UI.clear(lex_box)
	for id in GameData.lexicon:
		var e: Dictionary = GameData.lexicon[id]
		var known := GameState.knows_glyph(id)
		var row := UI.hbox(12)
		row.add_child(UI.glyphs(str(e.glyph) if known else "?", 30, T.GOLD_L if known else T.MUTED))
		row.add_child(UI.label(str(e.meaning) if known else Loc.t("hg_unknown"), 16, T.PAPYRUS if known else T.MUTED, true))
		lex_box.add_child(row)
	_build_puzzles()


func _build_puzzles() -> void:
	UI.clear(puzzle_box)
	var any := false
	for cid in GameData.cases:
		for tr in GameData.get_case(cid).get("translations", []):
			if not GameState.has_evidence(str(tr.evidence)):
				continue
			any = true
			puzzle_box.add_child(_puzzle(cid, tr))
	if not any:
		puzzle_box.add_child(UI.ink(Loc.t("hg_no_puzzles"), 17))


func _puzzle(cid: String, tr: Dictionary) -> Control:
	var v := UI.vbox(10)
	var done := false
	for e in tr.get("effects", []):
		if e.has("set_flag") and GameState.has_flag(str(e.set_flag)):
			done = true
	v.add_child(UI.title("%s – %s" % [tr.evidence, tr.title], 22, T.RED_INK))
	if done:
		v.add_child(UI.rich("[b]✓ %s[/b]\n%s" % [Loc.t("hg_done"), tr.success], 19))
		return v
	v.add_child(UI.ink(Loc.t("hg_instructions"), 15))
	var known := []
	for id in GameState.data.lexicon:
		if GameData.lexicon.has(id):
			known.append(id)
	var row := UI.hbox(14)
	var key := str(tr.evidence)
	if not selections.has(key):
		selections[key] = []
		for g in tr.glyphs:
			selections[key].append(-1)
	var unknown := 0
	for gi in tr.glyphs.size():
		var g: Dictionary = tr.glyphs[gi]
		if not GameState.knows_glyph(str(g.answer)):
			unknown += 1
		var col := UI.vbox(6)
		col.add_child(UI.glyphs(str(g.g), 40, T.INK))
		var ob := OptionButton.new()
		ob.focus_mode = Control.FOCUS_NONE
		ob.add_item("?")
		for id in known:
			ob.add_item(str(GameData.lexicon[id].meaning))
		var sel: int = selections[key][gi]
		ob.select(sel + 1 if sel >= 0 else 0)
		ob.item_selected.connect(func(i): selections[key][gi] = i - 1)
		ob.custom_minimum_size.x = 150
		col.add_child(ob)
		row.add_child(col)
	v.add_child(row)
	if unknown > 0:
		v.add_child(UI.label(Loc.t("hg_unknown_count", [unknown]), 14, T.INK_L, true))
	v.add_child(UI.ink_button(Loc.t("hg_translate"), func(): _check(cid, tr, known)))
	if feedback.has(key):
		v.add_child(UI.label(str(feedback[key]), 15, T.RED_INK, true))
	return v


func _check(cid: String, tr: Dictionary, known: Array) -> void:
	var key := str(tr.evidence)
	var ok := true
	for gi in tr.glyphs.size():
		var sel: int = selections[key][gi]
		if sel < 0 or sel >= known.size() or known[sel] != str(tr.glyphs[gi].answer):
			ok = false
	if ok:
		Cond.apply(tr.get("effects", []), GameState, cid)
		GameState.toast.emit(Loc.t("toast_translated", [tr.title]), "glyph")
		feedback.erase(key)
		GameState.flush()
	else:
		feedback[key] = Loc.t("hg_wrong")
	refresh()
