extends "res://scripts/ui/widgets/overlay.gd"
## Az Emlékek Kamrája: a lelkek emlékeinek mélyebb vizsgálata. A homályos töredékek
## a megfelelő bizonyítékkal tisztázhatók.

var list_box: VBoxContainer
var detail: VBoxContainer
var current := ""
var current_case := ""
var feedback := ""


func build() -> void:
	var p := centered(Vector2(1260, 760))
	var v := UI.vbox(12)
	p.add_child(v)
	v.add_child(header(GameData.room("memories").name, "𓂀", GameData.room("memories").purpose))
	v.add_child(UI.separator())
	var h := UI.hbox(18)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	list_box = UI.vbox(8)
	list_box.custom_minimum_size.x = 300
	h.add_child(list_box)
	var right := UI.papyrus(26)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail = UI.vbox(12)
	right.add_child(UI.scroll(detail))
	h.add_child(right)
	refresh()


func refresh() -> void:
	UI.clear(list_box)
	for cid in GameData.cases:
		for m in GameData.get_case(cid).get("memories", []):
			if not GameState.memory_unlocked(m.id):
				continue
			if current == "":
				current = m.id
				current_case = cid
			var b := UI.button("%s   %s" % [m.get("glyph", "𓂀"), m.title], _pick.bind(m.id, cid))
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if m.id == current:
				b.add_theme_color_override("font_color", T.TURQ)
			list_box.add_child(b)
	if list_box.get_child_count() == 0:
		list_box.add_child(UI.label(Loc.t("mem_none"), 15, T.MUTED, true))
	_build_detail()


func _pick(mid: String, cid: String) -> void:
	current = mid
	current_case = cid
	feedback = ""
	refresh()


func _build_detail() -> void:
	UI.clear(detail)
	if current == "":
		detail.add_child(UI.ink(Loc.t("mem_intro"), 17))
		return
	var m: Dictionary = GameData.get_case(current_case)._memories[current]
	detail.add_child(UI.title(m.title, 28, T.RED_INK))
	detail.add_child(UI.label(Loc.t("mem_whose", [GameData.soul(current_case).get("name", "")]), 14, T.INK_L))
	var frags: Array = m.get("fragments", [])
	for i in frags.size():
		var f: Dictionary = frags[i]
		var key := "%s.%d" % [current, i]
		if f.get("blurred", false) and not GameState.is_clarified(key):
			var bp := UI.box_panel(Color(T.TURQ, 0.08), Color(T.TURQ.darkened(0.3), 0.6), 1, 14)
			var bv := UI.vbox(8)
			bp.add_child(bv)
			bv.add_child(UI.rich("[i][color=#5a6f6c]%s ░░░░ ▒▒░ ░▒░░░ ░░▒░[/color][/i]" % f.text, 18))
			bv.add_child(UI.label(Loc.t("mem_blurred"), 14, T.INK_L, true))
			var hh := UI.hbox(8)
			var ob := OptionButton.new()
			ob.focus_mode = Control.FOCUS_NONE
			var ids := []
			for ev in GameData.get_case(current_case).evidence:
				if GameState.has_evidence(ev.id):
					ids.append(ev.id)
					ob.add_item("%s – %s" % [ev.id, ev.title])
			hh.add_child(ob)
			hh.add_child(UI.ink_button(Loc.t("mem_clarify"), func(): _try_clarify(i, f, ids, ob.selected)))
			bv.add_child(hh)
			detail.add_child(bp)
		else:
			var txt := str(f.get("revealed", f.text)) if f.get("blurred", false) else str(f.text)
			var col := "[color=#1d5a55]" if f.get("blurred", false) else ""
			detail.add_child(UI.rich("%s%s%s" % [col, txt, "[/color]" if col != "" else ""], 18))
	if feedback != "":
		detail.add_child(UI.label(feedback, 15, T.RED_INK, true))


func _try_clarify(idx: int, f: Dictionary, ids: Array, sel: int) -> void:
	if sel < 0 or sel >= ids.size():
		return
	if ids[sel] == str(f.get("clarify_with", "")):
		GameState.clarify(current, idx, current_case)
		feedback = ""
		GameState.flush()
	else:
		feedback = Loc.t("mem_wrong")
	refresh()
