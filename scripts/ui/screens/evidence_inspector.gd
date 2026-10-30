extends "res://scripts/ui/widgets/overlay.gd"
## Bizonyíték részletes vizsgálata: kép vagy forgatható 3D tárgy, eszközök a rejtett
## részletekhez (megfordítás, lámpafény, nagyító, forgatás), ellentmondások, kapcsolatok.

const Illustration = preload("res://scripts/ui/widgets/illustration.gd")
const ModelViewer = preload("res://scripts/ui/widgets/model_viewer.gd")

const TOOL_GLYPH := {"flip": "↻", "lamp": "𓊽", "magnify": "◎", "rotate": "⟲"}

var cid := ""
var eid := ""
var ev: Dictionary
var illus: Control
var viewer: Control
var view_state := {}
var right_box: VBoxContainer
var tools_box: VBoxContainer


func _init(p_cid := "", p_eid := "") -> void:
	cid = p_cid
	eid = p_eid


func build() -> void:
	ev = GameData.evidence(eid)
	GameState.mark_inspected(eid)
	for a in ev.get("inspect", []):
		if GameState.is_revealed("%s.%s" % [eid, a.id]):
			view_state[str(a.tool)] = a.tool != "flip"
	var p := centered(Vector2(1380, 800))
	var h := UI.hbox(22)
	p.add_child(h)
	# bal oldal: kép / 3D
	var left := UI.vbox(12)
	left.custom_minimum_size.x = T.px(600)
	h.add_child(left)
	var frame := UI.box_panel(Color(T.DEEP, 0.8), T.GOLD, 2, 6)
	frame.custom_minimum_size = T.v2(600, 450)
	left.add_child(frame)
	if ev.has("model"):
		viewer = ModelViewer.new()
		viewer.custom_minimum_size = T.v2(580, 430)
		frame.add_child(viewer)
		viewer.setup(str(ev.model))
		viewer.rotated_back.connect(_on_rotated_back)
		var tip := UI.label(Loc.t("insp_rotate_tip_touch" if T.compact else "insp_rotate_tip"), 13, T.SAND)
		left.add_child(tip)
	else:
		illus = Illustration.new()
		illus.custom_minimum_size = T.v2(580, 430)
		frame.add_child(illus)
	_update_illus()
	tools_box = UI.vbox(8)
	left.add_child(tools_box)
	# jobb oldal: szöveg
	var paper := UI.papyrus(26)
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(paper)
	var pv := UI.vbox(10)
	paper.add_child(pv)
	var top := UI.hbox(10)
	top.add_child(UI.label("%s · %s" % [eid, Loc.t("type_" + str(ev.get("type", "document")))], 15, T.INK_L))
	top.add_child(UI.spacer())
	top.add_child(UI.ink_button(Loc.t("btn_close") + "  ✕", close))
	pv.add_child(top)
	pv.add_child(UI.title(ev.title, 30, T.RED_INK))
	right_box = UI.vbox(10)
	pv.add_child(UI.scroll(right_box))
	var bh := UI.hbox(10)
	bh.add_child(UI.ink_button(Loc.t("insp_compare"), func(): main.open_compare(cid, eid)))
	if ev.has("translation"):
		var tb := UI.ink_button(Loc.t("insp_translate"), func(): main.open_room_screen("hieroglyphs"))
		tb.disabled = not GameState.room_status("hieroglyphs").open or GameState.has_flag("k03_translated")
		bh.add_child(tb)
	pv.add_child(bh)
	refresh()


func refresh() -> void:
	_build_tools()
	_build_text()
	_update_illus()


func _update_illus() -> void:
	if illus != null:
		illus.setup(str(ev.get("illustration", "document")), eid, view_state, GameState.is_corrupted(eid))


func _build_tools() -> void:
	UI.clear(tools_box)
	var actions: Array = ev.get("inspect", [])
	if actions.is_empty():
		return
	tools_box.add_child(UI.title(Loc.t("insp_tools"), 17, T.GOLD))
	for a in actions:
		var key := "%s.%s" % [eid, a.id]
		var done := GameState.is_revealed(key)
		var txt := "%s  %s" % [TOOL_GLYPH.get(a.tool, "•"), a.label]
		if done:
			txt += "  ✓"
		var b := UI.button(txt, _use_tool.bind(a))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if GameState.is_corrupted(eid):
			b.disabled = true
		tools_box.add_child(b)


func _use_tool(a: Dictionary) -> void:
	var tool := str(a.tool)
	match tool:
		"flip":
			view_state["flipped"] = not view_state.get("flipped", false)
		"lamp":
			view_state["lamp"] = true
		"magnify":
			view_state["magnify"] = true
		"rotate":
			if viewer != null:
				viewer.show_back()
	GameState.reveal(eid, str(a.id))
	GameState.flush()
	refresh()


func _on_rotated_back() -> void:
	for a in ev.get("inspect", []):
		if a.tool == "rotate":
			GameState.reveal(eid, str(a.id))
	GameState.flush()
	refresh()


func _build_text() -> void:
	UI.clear(right_box)
	var corrupted := GameState.is_corrupted(eid)
	if corrupted:
		right_box.add_child(UI.rich("[color=#6b2f8a][b]%s[/b][/color]" % Loc.t("insp_corrupted"), 16))
	right_box.add_child(UI.ink(ev.get("description", ""), 17))
	var body := GameState.evidence_text(eid)
	if corrupted:
		body = _scramble(body)
	var doc := UI.box_panel(Color(T.INK, 0.06), Color(T.INK_L, 0.4), 1, 14)
	doc.add_child(UI.rich("[i]%s[/i]" % body, 18))
	right_box.add_child(doc)
	# feltárt rejtett részletek
	for a in ev.get("inspect", []):
		if GameState.is_revealed("%s.%s" % [eid, a.id]):
			var rp := UI.box_panel(Color(T.TURQ, 0.12), Color(T.TURQ.darkened(0.3), 0.8), 1, 12)
			var rv := UI.vbox(4)
			rv.add_child(UI.label("%s  %s" % [TOOL_GLYPH.get(a.tool, "•"), Loc.t("insp_found_" + str(a.tool))], 14, T.TURQ.darkened(0.45)))
			rv.add_child(UI.rich(str(a.text), 17))
			rp.add_child(rv)
			right_box.add_child(rp)
	# fordítás
	if ev.has("translation") and GameState.has_flag("k03_translated"):
		for tr in GameData.get_case(cid).get("translations", []):
			if tr.evidence == eid:
				var tp := UI.box_panel(Color(T.GOLD, 0.15), T.GOLD_D, 1, 12)
				tp.add_child(UI.rich("[b]%s[/b]\n%s" % [Loc.t("insp_translation"), tr.success], 17))
				right_box.add_child(tp)
	elif ev.has("translation"):
		var hint := Loc.t("insp_needs_translation") if GameState.room_status("hieroglyphs").open else Loc.t("insp_needs_translation_locked")
		right_box.add_child(UI.ink(hint, 15))
	# ellentmondások (csak ha mindkét fél ismert)
	for c in ev.get("contradictions", []):
		if GameState.has_evidence(str(c.with)):
			var other := GameData.evidence(str(c.with))
			var cp := UI.box_panel(Color(T.RED, 0.12), Color(T.RED, 0.7), 1, 12)
			cp.add_child(UI.rich("[color=#8a2a14][b]⚠ %s[/b][/color] %s – %s" % [Loc.t("insp_contradiction"),
				other.get("title", ""), c.text], 16))
			right_box.add_child(cp)
	for other in GameData.get_case(cid).evidence:
		for c in other.get("contradictions", []):
			if str(c.with) == eid and GameState.has_evidence(other.id):
				var cp := UI.box_panel(Color(T.RED, 0.12), Color(T.RED, 0.7), 1, 12)
				cp.add_child(UI.rich("[color=#8a2a14][b]⚠ %s[/b][/color] %s – %s" % [Loc.t("insp_contradicted_by"),
					other.title, c.text], 16))
				right_box.add_child(cp)
	right_box.add_child(UI.separator(T.INK_L))
	# kapcsolatok
	right_box.add_child(UI.title(Loc.t("insp_assoc"), 17, T.RED_INK))
	var f := UI.flow(6)
	for id in ev.get("associated", []):
		var card := GameData.card(id)
		if GameState.card_available(id):
			f.add_child(UI.badge("%s %s" % [card.get("glyph", ""), card.get("title", id)],
				T.CATEGORY_COLORS.get(card.get("category", ""), T.MUTED).darkened(0.25), 14))
		else:
			f.add_child(UI.badge(Loc.t("insp_unknown_link"), T.MUTED.darkened(0.3), 14))
	right_box.add_child(f)
	var rel := GameState.get_reliability(eid)
	right_box.add_child(UI.label("%s: %s" % [Loc.t("insp_reliability"), UI.reliability_text(rel)], 16, T.INK))
	right_box.add_child(UI.label(Loc.t("insp_reliability_note"), 13, T.INK_L, true))
	if ev.has("implication"):
		right_box.add_child(UI.rich("[b]%s[/b] %s" % [Loc.t("insp_implication"), ev.implication], 16))


func _scramble(s: String) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(eid)
	var out := ""
	for ch in s:
		if ch == " " or ch == "\n":
			out += ch
		elif rng.randf() < 0.55:
			out += ["░", "▒", "𓇽", "·", "§"][rng.randi() % 5]
		else:
			out += ch
	return out
