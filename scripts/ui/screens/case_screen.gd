extends "res://scripts/ui/widgets/overlay.gd"
## Egy lélek ügyének központja: érkezés, nyomozás, bizonyítékok, storyboard, ítélet.

const Dlg = preload("res://scripts/systems/dialogue.gd")
const Cond = preload("res://scripts/systems/conditions.gd")
const Judgment = preload("res://scripts/systems/judgment.gd")
const Storyboard = preload("res://scripts/ui/widgets/storyboard.gd")
const EvidenceTile = preload("res://scripts/ui/widgets/evidence_tile.gd")
const ArtFrame = preload("res://scripts/ui/widgets/art_frame.gd")
const ProgressStrip = preload("res://scripts/ui/widgets/progress_strip.gd")

const TABS := ["briefing", "investigation", "evidence", "storyboard", "judgment"]
const TAB_GLYPHS := {"briefing": "𓊛", "investigation": "𓁹", "evidence": "𓏞", "storyboard": "𓏛", "judgment": "𓆄"}

var cid := ""
var case_data: Dictionary
var tab := "briefing"
var content: PanelContainer
var tab_buttons := {}
var progress_strip: Control
var storyboard: Control
var questions_holder: VBoxContainer


func _init(p_cid := "", p_tab := "") -> void:
	cid = p_cid
	if p_tab != "":
		tab = p_tab
	dim = 0.55


func build() -> void:
	case_data = GameData.get_case(cid)
	var soul := GameData.soul(cid)
	if tab == "briefing" and GameState.case_state(cid).status == "in_progress" and GameState.node_visited("_briefed." + cid):
		tab = "investigation"
	GameState.visit_node("_briefed." + cid)
	var p := framed(26)
	var v := UI.vbox(12)
	p.add_child(v)
	v.add_child(_banner(soul))
	var body := UI.hbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	var tabs := UI.vbox(8)
	tabs.custom_minimum_size.x = T.px(210)
	body.add_child(tabs)
	for t in TABS:
		var b := UI.button("%s   %s" % [TAB_GLYPHS[t], Loc.t("tab_" + t)], _on_tab.bind(t))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 18)
		tab_buttons[t] = b
		tabs.add_child(b)
	var nb := UI.button(Loc.t("btn_notes"), func(): main.open_notes(cid))
	nb.alignment = HORIZONTAL_ALIGNMENT_LEFT
	nb.add_theme_font_size_override("font_size", 18)
	tabs.add_child(UI.gap(6))
	tabs.add_child(nb)
	tabs.add_child(UI.spacer(false))
	questions_holder = UI.vbox(0)
	tabs.add_child(questions_holder)
	if not T.compact:
		questions_holder.add_child(_questions_panel())
	content = PanelContainer.new()
	content.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(content)
	_show_tab()


func _on_tab(t: String) -> void:
	tab = t
	_show_tab()


func _show_tab() -> void:
	UI.clear(content)
	storyboard = null
	for t in tab_buttons:
		var b: Button = tab_buttons[t]
		if t == tab:
			b.add_theme_stylebox_override("normal", T.tablet("selected"))
			b.add_theme_color_override("font_color", T.GOLD_L)
		else:
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_color_override("font_color")
	match tab:
		"briefing":
			content.add_child(_briefing())
		"investigation":
			content.add_child(_investigation())
		"evidence":
			content.add_child(_evidence())
		"storyboard":
			storyboard = Storyboard.new(cid)
			storyboard.main = main
			content.add_child(storyboard)
		"judgment":
			content.add_child(_judgment())
	_update_progress()


func refresh() -> void:
	_update_progress()
	UI.clear(questions_holder)
	if not T.compact:
		questions_holder.add_child(_questions_panel())
	if tab == "storyboard":
		if storyboard != null:
			storyboard.refresh()
	else:
		_show_tab()


func _update_progress() -> void:
	var found := 0
	for ev in case_data.evidence:
		if GameState.has_evidence(ev.id):
			found += 1
	var filled := 0
	var board := GameState.board(cid)
	for sc in case_data.scenes:
		if not board.get(sc.id, []).is_empty():
			filled += 1
	progress_strip.set_values(found, case_data.evidence.size(), filled, case_data.scenes.size())
	var new_inv := false
	for br in case_data.get("investigation", []) + case_data.get("encounters", []):
		if Cond.check(br.get("unlock", true), GameState) and Dlg.has_new(case_data, br.dialogue, GameState):
			new_inv = true
	var new_ev := false
	for ev in case_data.evidence:
		if GameState.has_evidence(ev.id) and not GameState.is_inspected(ev.id):
			new_ev = true
	tab_buttons.investigation.text = "%s   %s%s" % [TAB_GLYPHS.investigation, Loc.t("tab_investigation"), "  •" if new_inv else ""]
	tab_buttons.evidence.text = "%s   %s%s" % [TAB_GLYPHS.evidence, Loc.t("tab_evidence"), "  •" if new_ev else ""]


## Fejlécsáv: a lélek illusztrációja a háttérben, rajta cím, alcím, bezárás és haladásjelző.
func _banner(soul: Dictionary) -> Control:
	var h := T.px(190) if not T.compact else 150.0
	var root := Control.new()
	root.custom_minimum_size = Vector2(0, h)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var art := ArtFrame.new()
	art.setup("souls", cid, "", "gold")
	art.fade_bottom = 0.0
	art.focus = Vector2(0.5, 0.15)
	UI.full_rect(art)
	root.add_child(art)
	var shade := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.05, 0.07, 0.13, 0.95))
	grad.set_color(1, Color(0.05, 0.07, 0.13, 0.0))
	grad.add_point(0.55, Color(0.05, 0.07, 0.13, 0.75))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(1, 0)
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(shade)
	root.add_child(shade)
	var m := UI.margin(null, 28, 18, 18, 14)
	UI.full_rect(m)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(m)
	var v := UI.vbox(4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	var top := UI.hbox(12)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tv := UI.vbox(2)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(UI.title("%s, %s" % [soul.name, soul.epithet], 34 if not T.compact else 28, T.GOLD_L))
	if not T.compact:
		tv.add_child(UI.label(Loc.t("case_subtitle"), 17, T.PAPYRUS, true))
	top.add_child(tv)
	top.add_child(UI.spacer())
	var cb := UI.button(Loc.t("btn_close") + "  ✕", close)
	cb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(cb)
	v.add_child(top)
	v.add_child(UI.spacer(false))
	progress_strip = ProgressStrip.new()
	v.add_child(progress_strip)
	return root


func _questions_panel() -> Control:
	var p := UI.box_panel(Color(T.DEEP, 0.6), T.GOLD_D, 1, 12)
	var v := UI.vbox(6)
	p.add_child(v)
	v.add_child(UI.title(Loc.t("case_questions"), 16, T.GOLD))
	for q in case_data.get("questions", []):
		var done: bool = Cond.check(q.get("done", false), GameState)
		var l := UI.label(("✓ " if done else "○ ") + str(q.text), 14, T.ANKH if done else T.PAPYRUS, true)
		v.add_child(l)
	return p


# ------------------------------------------------------------ érkezés
func _briefing() -> Control:
	var p := UI.papyrus(34)
	var v := UI.vbox(14)
	if T.compact:
		# telefonon a nyitott kérdések az Érkezés lapra kerülnek
		v.add_child(_questions_panel())
	v.add_child(UI.title(Loc.t("brief_arrival"), 26, T.RED_INK))
	v.add_child(UI.rich(str(case_data.arrival).replace("\n\n", "\n\n"), 19))
	v.add_child(UI.separator(T.INK_L))
	v.add_child(UI.title(Loc.t("brief_known"), 20, T.RED_INK))
	v.add_child(UI.rich(str(case_data.biography), 17))
	v.add_child(UI.gap(4))
	v.add_child(UI.rich(Loc.t("brief_howto"), 16, T.INK_L))
	var h := UI.hbox(12)
	h.add_child(UI.ink_button(Loc.t("brief_go_investigate"), _on_tab.bind("investigation")))
	h.add_child(UI.ink_button(Loc.t("brief_go_evidence"), _on_tab.bind("evidence")))
	v.add_child(h)
	p.add_child(UI.scroll(v))
	return p


# ------------------------------------------------------------ nyomozás
func _investigation() -> Control:
	var outer := UI.vbox(14)
	outer.add_child(UI.label(Loc.t("inv_intro"), 16, T.SAND, true))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for br in case_data.get("investigation", []):
		grid.add_child(_branch_card(br, str(br.get("letter", ""))))
	outer.add_child(grid)
	var enc := []
	for e in case_data.get("encounters", []):
		if Cond.check(e.get("unlock", true), GameState):
			enc.append(e)
	outer.add_child(UI.title(Loc.t("inv_encounters"), 20, T.GOLD))
	if enc.is_empty():
		outer.add_child(UI.label(Loc.t("inv_no_encounters"), 15, T.MUTED, true))
	else:
		var g2 := GridContainer.new()
		g2.columns = 2
		g2.add_theme_constant_override("h_separation", 14)
		g2.add_theme_constant_override("v_separation", 14)
		for e in enc:
			g2.add_child(_branch_card(e, ""))
		outer.add_child(g2)
	return UI.scroll(outer)


func _branch_card(br: Dictionary, letter: String) -> Control:
	var p := UI.papyrus(18)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := UI.hbox(14)
	p.add_child(h)
	var badge := UI.box_panel(T.LAPIS, T.GOLD, 2, 8, 10)
	badge.custom_minimum_size = T.v2(64, 64)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var gl := UI.glyphs(letter if letter != "" else str(br.get("glyph", "?")), 30, T.GOLD)
	gl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(gl)
	var art_id := "%s_%s" % [cid, str(br.get("dialogue", ""))]
	var kind := "spirits" if ArtFrame.find("spirits", art_id) != null else "portraits"
	if ArtFrame.find(kind, art_id) != null:
		# a megidézett ka képe, a sarkában az ág betűjele
		var art := ArtFrame.new()
		art.setup(kind, art_id)
		art.fade_bottom = 0.0
		var s := T.px(118)
		art.custom_minimum_size = Vector2(s, s)
		art.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		if letter != "":
			badge.custom_minimum_size = T.v2(34, 34)
			gl.add_theme_font_size_override("font_size", 18)
			badge.position = Vector2(4, 4)
			art.add_child(badge)
		h.add_child(art)
	else:
		h.add_child(badge)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var th := UI.hbox(8)
	th.add_child(UI.title(br.title, 20, T.RED_INK))
	if Dlg.has_new(case_data, br.dialogue, GameState):
		th.add_child(UI.badge(Loc.t("tag_new_topics"), T.TURQ.darkened(0.2), 12))
	v.add_child(th)
	if br.has("location"):
		v.add_child(UI.label(br.location, 14, T.INK_L))
	v.add_child(UI.ink(br.desc, 15))
	var bh := UI.hbox(8)
	var b := UI.ink_button(Loc.t("inv_summon"), func(): main.open_dialogue(cid, br.dialogue))
	bh.add_child(b)
	if not Dlg.heard(case_data, br.dialogue, GameState).is_empty():
		var rb := UI.ink_button(Loc.t("inv_replay"), func(): main.open_dialogue(cid, br.dialogue, true))
		rb.tooltip_text = Loc.t("inv_replay_tip")
		bh.add_child(rb)
	v.add_child(bh)
	h.add_child(v)
	return p


# ------------------------------------------------------------ bizonyítékok
func _evidence() -> Control:
	var h := UI.hbox(16)
	var left := UI.vbox(10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := UI.hbox(10)
	var found := 0
	for ev in case_data.evidence:
		if GameState.has_evidence(ev.id):
			found += 1
	top.add_child(UI.label(Loc.t("ev_found", [found, case_data.evidence.size()]), 16, T.SAND))
	top.add_child(UI.spacer())
	top.add_child(UI.button(Loc.t("ev_compare"), func(): main.open_compare(cid)))
	left.add_child(top)
	var f := UI.flow(12)
	for ev in case_data.evidence:
		if not GameState.has_evidence(ev.id):
			continue
		var tile := EvidenceTile.new()
		tile.setup(ev.id)
		tile.pressed.connect(func(eid): main.open_evidence(cid, eid))
		f.add_child(tile)
	for i in case_data.evidence.size() - found:
		var ph := UI.box_panel(Color(T.DEEP, 0.4), Color(T.GOLD_D, 0.35), 1, 10)
		ph.custom_minimum_size = T.v2(200, 128)
		var l := UI.glyphs("?", 40, Color(T.GOLD_D, 0.5))
		ph.add_child(l)
		ph.tooltip_text = Loc.t("ev_hidden")
		f.add_child(ph)
	left.add_child(UI.scroll(f))
	h.add_child(left)

	var right := UI.box_panel(Color(T.DEEP, 0.55), T.GOLD_D, 1, 14)
	right.custom_minimum_size.x = T.px(330)
	var rv := UI.vbox(10)
	right.add_child(rv)
	rv.add_child(UI.title(Loc.t("ev_memories"), 20, T.TURQ))
	var any := false
	for m in case_data.get("memories", []):
		if GameState.memory_unlocked(m.id):
			any = true
			var mh := UI.hbox(8)
			mh.add_child(UI.glyphs(m.get("glyph", "𓂀"), 22, T.TURQ))
			mh.add_child(UI.label(m.title, 16, T.PAPYRUS, true))
			rv.add_child(mh)
	if not any:
		rv.add_child(UI.label(Loc.t("ev_no_memories"), 14, T.MUTED, true))
	else:
		rv.add_child(UI.button(Loc.t("ev_open_memories"), func(): main.open_room_screen("memories")))
	rv.add_child(UI.separator())
	rv.add_child(UI.title(Loc.t("ev_lexicon"), 20, T.GOLD))
	var lex := UI.flow(10)
	for id in GameState.data.lexicon:
		var e: Dictionary = GameData.lexicon.get(id, {})
		if e.is_empty():
			continue
		var g := UI.glyphs(str(e.glyph), 24, T.GOLD_L)
		g.tooltip_text = str(e.meaning)
		g.mouse_filter = Control.MOUSE_FILTER_PASS
		lex.add_child(g)
	rv.add_child(lex)
	rv.add_child(UI.separator())
	rv.add_child(UI.label(Loc.t("ev_legend"), 13, T.SAND, true))
	h.add_child(right)
	return h


# ------------------------------------------------------------ ítélet
func _judgment() -> Control:
	var cs := GameState.case_state(cid)
	var p := UI.papyrus(30)
	var v := UI.vbox(14)
	p.add_child(v)
	if cs.status == "judged":
		var res: Dictionary = cs.get("result", {})
		v.add_child(UI.title(Loc.t("jt_already"), 24, T.RED_INK))
		v.add_child(UI.title(str(res.get("title", "")), 30, T.INK))
		v.add_child(UI.ink(GameData.category(cs.category).get("label", "") + " · " +
			GameData.destination_label(str(res.get("destination", ""))), 18))
		v.add_child(UI.ink_button(Loc.t("jt_view_result"), func(): main.show_result(cid, res, true)))
		return p
	var comp := Judgment.compute(case_data, GameState)
	v.add_child(UI.title(Loc.t("jt_title"), 26, T.RED_INK))
	v.add_child(UI.ink(Loc.t("jt_intro"), 17))
	for sc in case_data.scenes:
		var r: Dictionary = comp.slots[sc.id]
		var row := UI.hbox(10)
		row.add_child(UI.label("%s. %s" % [sc.get("numeral", ""), sc.title], 18, T.INK))
		row.add_child(UI.spacer())
		row.add_child(UI.label(r.title if r.title != "" else "—", 16, T.INK_L))
		row.add_child(UI.state_badge(r.state))
		v.add_child(row)
	v.add_child(UI.separator(T.INK_L))
	if not comp.complete:
		v.add_child(UI.ink(Loc.t("jt_incomplete"), 17))
		v.add_child(UI.ink_button(Loc.t("jt_go_storyboard"), _on_tab.bind("storyboard")))
	else:
		v.add_child(UI.ink(Loc.t("jt_ready"), 17))
		var b := UI.ink_button(Loc.t("jt_begin"), func(): main.open_judgment(cid))
		b.add_theme_font_size_override("font_size", 22)
		v.add_child(b)
	return UI.scroll(p)
