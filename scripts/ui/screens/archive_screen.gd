extends "res://scripts/ui/widgets/overlay.gd"
## A Lelkek Archívuma: minden bizonyíték, az ügyeken átívelő nyomok és az eddigi ítéletek.

const EvidenceTile = preload("res://scripts/ui/widgets/evidence_tile.gd")

var tab := "evidence"
var content: Control
var tab_buttons := {}


func _init(p_tab := "") -> void:
	if p_tab != "":
		tab = p_tab


func build() -> void:
	var p := framed(40)
	var v := UI.vbox(12)
	p.add_child(v)
	v.add_child(header(GameData.room("archive").name, "𓏞", GameData.room("archive").purpose))
	var th := UI.hbox(10)
	for t in ["evidence", "clues", "judgments"]:
		var b := UI.button(Loc.t("arch_tab_" + t), _on_tab.bind(t))
		tab_buttons[t] = b
		th.add_child(b)
	v.add_child(th)
	v.add_child(UI.separator())
	content = UI.vbox(10)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(content)
	refresh()


func _on_tab(t: String) -> void:
	tab = t
	refresh()


func refresh() -> void:
	UI.clear(content)
	for t in tab_buttons:
		(tab_buttons[t] as Button).add_theme_color_override("font_color", T.GOLD_L if t == tab else T.PAPYRUS)
	match tab:
		"evidence":
			content.add_child(_evidence())
		"clues":
			content.add_child(_clues())
		"judgments":
			content.add_child(_judgments())


func _evidence() -> Control:
	var v := UI.vbox(14)
	var any := false
	for cid in GameData.cases:
		var case_data := GameData.get_case(cid)
		var f := UI.flow(12)
		for ev in case_data.evidence:
			if GameState.has_evidence(ev.id):
				var tile := EvidenceTile.new()
				tile.setup(ev.id)
				tile.pressed.connect(func(eid): main.open_evidence(cid, eid))
				f.add_child(tile)
		if f.get_child_count() > 0:
			any = true
			var soul := GameData.soul(cid)
			v.add_child(UI.title("%s  %s, %s" % [soul.glyph, soul.name, soul.epithet], 22, T.GOLD))
			v.add_child(f)
	if not any:
		v.add_child(UI.label(Loc.t("arch_empty"), 16, T.MUTED))
	return UI.scroll(v)


func _clues() -> Control:
	var v := UI.vbox(14)
	var m := GameData.mystery
	v.add_child(UI.title(str(m.get("title", "")), 24, T.GOLD))
	v.add_child(UI.label(str(m.get("intro", "")), 16, T.SAND, true))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	for c in m.get("clues", []):
		var found := GameState.has_clue(c.id)
		var p := UI.papyrus(16) if found else UI.box_panel(Color(T.DEEP, 0.5), Color(T.GOLD_D, 0.4), 1, 16)
		p.custom_minimum_size = Vector2(360, 150)
		var pv := UI.vbox(6)
		p.add_child(pv)
		if found:
			var hh := UI.hbox(8)
			hh.add_child(UI.glyphs(str(c.glyph), 26, T.RED_INK))
			hh.add_child(UI.title(str(c.title), 18, T.RED_INK))
			pv.add_child(hh)
			pv.add_child(UI.ink(str(c.text), 15))
		else:
			var soul := GameData.soul(str(c.case))
			pv.add_child(UI.glyphs("?", 30, Color(T.GOLD_D, 0.6)))
			pv.add_child(UI.label(Loc.t("arch_clue_hidden", [soul.get("name", Loc.t("arch_final"))]), 14, T.MUTED, true))
		grid.add_child(p)
	v.add_child(grid)
	v.add_child(UI.label(str(m.get("door_text", "")), 15, T.GOLD_L, true))
	return UI.scroll(v)


func _judgments() -> Control:
	var v := UI.vbox(10)
	var hist: Array = GameState.data.history
	if hist.is_empty():
		v.add_child(UI.label(Loc.t("arch_no_judgments"), 16, T.MUTED))
	for hrec in hist:
		var soul := GameData.soul(str(hrec.case))
		var cat := GameData.category(str(hrec.category))
		var p := UI.box_panel(Color(T.DEEP, 0.6), Color(str(cat.get("color", "d4a640"))), 1, 14)
		var hh := UI.hbox(14)
		p.add_child(hh)
		hh.add_child(UI.glyphs(str(soul.get("glyph", "")), 32, T.GOLD))
		var tv := UI.vbox(2)
		tv.add_child(UI.title("%s – %s" % [soul.get("name", ""), hrec.title], 20, T.GOLD_L))
		tv.add_child(UI.label("%s · %s" % [cat.get("label", ""), GameData.destination_label(str(hrec.destination))], 15, T.SAND))
		hh.add_child(tv)
		hh.add_child(UI.spacer())
		var cs := GameState.case_state(str(hrec.case))
		if cs.has("result"):
			hh.add_child(UI.button(Loc.t("jt_view_result"), func(): main.show_result(str(hrec.case), cs.result, true)))
		v.add_child(p)
	return UI.scroll(v)
