extends "res://scripts/ui/widgets/overlay.gd"
## A Lelkek Táblája: a Házba érkezett lelkek és ügyeik állapota.

const Cond = preload("res://scripts/systems/conditions.gd")

var row: HBoxContainer


func build() -> void:
	var p := centered(Vector2(1240, 640))
	var v := UI.vbox(16)
	p.add_child(v)
	v.add_child(header(Loc.t("souls_title"), "𓁹", Loc.t("souls_subtitle")))
	v.add_child(UI.separator())
	row = UI.hbox(20)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(row)
	refresh()


func refresh() -> void:
	UI.clear(row)
	for s in GameData.souls:
		row.add_child(_soul_card(s))


func _soul_card(s: Dictionary) -> Control:
	var unlocked: bool = Cond.check(s.get("unlock", true), GameState)
	var playable: bool = s.get("playable", false) and GameData.cases.has(s.id)
	var p := UI.papyrus(22)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not unlocked or not playable:
		p.modulate = Color(0.62, 0.62, 0.66)
	var v := UI.vbox(10)
	p.add_child(v)
	v.add_child(UI.glyphs(s.glyph, 64, T.INK if unlocked else T.INK_L))
	v.add_child(UI.title(s.name, 30, T.RED_INK, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.label(s.epithet, 17, T.INK_L, false, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.separator(T.INK_L))
	v.add_child(UI.ink(s.summary if unlocked else Loc.t("souls_locked_summary"), 16))
	v.add_child(UI.spacer(false))
	var status := ""
	var btn_text := ""
	var cb := Callable()
	if not unlocked:
		status = Loc.t("souls_status_locked")
	elif not playable:
		status = str(s.get("coming", Loc.t("souls_status_coming")))
	else:
		var cs: Dictionary = GameState.case_state(s.id)
		var case_data := GameData.get_case(s.id)
		match str(cs.get("status", "new")):
			"new":
				status = Loc.t("souls_status_new")
				btn_text = Loc.t("souls_btn_begin")
			"in_progress":
				var found := 0
				for ev in case_data.evidence:
					if GameState.has_evidence(ev.id):
						found += 1
				status = Loc.t("souls_status_progress", [found, case_data.evidence.size()])
				btn_text = Loc.t("souls_btn_continue")
			"judged":
				var res: Dictionary = cs.get("result", {})
				status = Loc.t("souls_status_judged", [res.get("title", ""), GameData.category(cs.category).get("label", ""),
					GameData.destination_label(str(res.get("destination", "")))])
				btn_text = Loc.t("souls_btn_view")
		cb = func(): main.open_case(s.id, "judgment" if GameState.case_done(s.id) else "")
	var st := UI.label(status, 15, T.INK, true)
	st.add_theme_font_override("font", T.font_title)
	v.add_child(st)
	if btn_text != "":
		var b := UI.ink_button(btn_text, cb)
		v.add_child(b)
	return p
