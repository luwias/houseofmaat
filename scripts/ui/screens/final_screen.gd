extends "res://scripts/ui/widgets/overlay.gd"
## A Ház ítélete: az átfogó rejtély feloldása az Elfeledett Szárny belső csarnokában.

const House = preload("res://scripts/systems/house_judgment.gd")
const Cond = preload("res://scripts/systems/conditions.gd")

var box: VBoxContainer
var answers := {}
var pickers := {}


func _init() -> void:
	dim = 0.8


func build() -> void:
	var p := framed(30)
	box = UI.vbox(14)
	p.add_child(box)
	refresh()


func refresh() -> void:
	UI.clear(box)
	var fin := House.final_data()
	box.add_child(header(str(fin.get("title", "")), "𓃀", Loc.t("final_subtitle")))
	box.add_child(UI.separator())
	if GameState.has_flag("final_judged"):
		box.add_child(_result_view(GameState.data.get("final_result", {})))
		return
	var h := UI.hbox(18)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(h)

	# bal: nyomozás a belső csarnokban és a nyomok
	var left := UI.papyrus(24)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lv := UI.vbox(10)
	left.add_child(UI.scroll(lv))
	h.add_child(left)
	lv.add_child(UI.rich(str(fin.get("intro", "")), 17))
	lv.add_child(UI.separator(T.INK_L))
	for a in fin.get("actions", []):
		var done := false
		for e in a.get("effects", []):
			if e.has("clue") and GameState.has_clue(str(e.clue)):
				done = true
		if done:
			lv.add_child(UI.rich("[color=#1d5a55]✓ %s[/color]\n%s" % [a.label, a.text], 16))
		elif Cond.check(a.get("requires", true), GameState):
			lv.add_child(UI.ink_button(str(a.label), _do_action.bind(a)))
	lv.add_child(UI.separator(T.INK_L))
	var found: int = GameState.data.clues.size()
	var total: int = GameData.mystery.get("clues", []).size()
	lv.add_child(UI.title(Loc.t("final_clues", [found, total]), 18, T.RED_INK))
	for c in GameData.mystery.get("clues", []):
		if GameState.has_clue(c.id):
			lv.add_child(UI.rich("[b]%s %s[/b] – %s" % [c.glyph, c.title, c.text], 15))
		else:
			lv.add_child(UI.label("? " + Loc.t("final_clue_missing"), 14, T.INK_L, true))

	# jobb: a három kérdés
	var right := UI.vbox(12)
	right.custom_minimum_size.x = T.px(520)
	h.add_child(right)
	right.add_child(UI.title(Loc.t("final_questions"), 22, T.GOLD))
	right.add_child(UI.label(Loc.t("final_questions_hint"), 14, T.SAND, true))
	for q in fin.get("questions", []):
		right.add_child(UI.label(str(q.text), 17, T.PAPYRUS, true))
		var ob := OptionButton.new()
		ob.focus_mode = Control.FOCUS_NONE
		ob.add_item(Loc.t("final_pick"))
		var ids := [""]
		for o in q.options:
			ob.add_item(str(o.label))
			ids.append(str(o.id))
		var cur := str(answers.get(q.id, ""))
		ob.select(maxi(0, ids.find(cur)))
		ob.item_selected.connect(_on_pick.bind(str(q.id), ids))
		ob.custom_minimum_size.y = T.px(44)
		right.add_child(ob)
		pickers[q.id] = ob
	right.add_child(UI.spacer(false))
	var b := UI.button(Loc.t("final_pronounce"), _pronounce)
	b.add_theme_font_size_override("font_size", 21)
	b.disabled = answers.size() < fin.get("questions", []).size()
	right.add_child(b)


func _on_pick(idx: int, qid: String, ids: Array) -> void:
	if idx <= 0:
		answers.erase(qid)
	else:
		answers[qid] = ids[idx]
	refresh()


func _do_action(a: Dictionary) -> void:
	Cond.apply(a.get("effects", []), GameState)
	GameState.flush()
	refresh()


func _pronounce() -> void:
	main.confirm(Loc.t("final_confirm"), _do_pronounce, Loc.t("final_pronounce"))


func _do_pronounce() -> void:
	var res := House.resolve(answers.duplicate(), GameState)
	if res.is_empty():
		return
	House.apply(res, GameState)
	GameState.flush()
	refresh()


func _result_view(res: Dictionary) -> Control:
	var h := UI.hbox(18)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := UI.papyrus(28)
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(12)
	paper.add_child(UI.scroll(v))
	h.add_child(paper)
	v.add_child(UI.title(str(res.get("title", "")), 34, T.RED_INK, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.rich(str(res.get("narrative", "")), 18))
	v.add_child(UI.rich("[i]%s[/i]" % res.get("epilogue", ""), 17))
	v.add_child(UI.separator(T.INK_L))
	v.add_child(UI.title(Loc.t("final_fates"), 18, T.RED_INK))
	for f in res.get("fates", []):
		var cat := GameData.category(str(f.category))
		v.add_child(UI.ink("• %s – „%s” · %s · %s" % [f.name, f.title, cat.get("label", ""), f.destination], 16))
	if not bool(res.get("just", false)):
		v.add_child(UI.separator(T.INK_L))
		v.add_child(UI.title(Loc.t("final_truth_title"), 18, T.RED_INK))
		v.add_child(UI.rich(Loc.t("final_truth"), 16))
	var side := UI.vbox(10)
	side.custom_minimum_size.x = T.px(320)
	side.add_child(UI.title(Loc.t("res_temple"), 18, T.GOLD))
	var eff: Dictionary = res.get("effects", {})
	for k in ["maat", "ankh", "duat"]:
		var d := int(eff.get(k, 0))
		var good: bool = (d > 0) != (k == "duat")
		var c := T.ANKH if good else T.RED
		if d == 0:
			c = T.SAND
		side.add_child(UI.label("%s   %s%d" % [Loc.t("stat_" + k), "+" if d > 0 else "", d], 17, c))
	side.add_child(UI.label(Loc.t("final_end_note"), 14, T.SAND, true))
	side.add_child(UI.spacer(false))
	side.add_child(UI.button(Loc.t("res_return"), func(): main.return_to_hall_after_judgment()))
	h.add_child(side)
	return h
