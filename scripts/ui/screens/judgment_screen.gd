extends "res://scripts/ui/widgets/overlay.gd"
## Ítélethozatal: a rekonstrukció összegzése, Thot hat paramétere és a négy lehetséges ítélet.

const Judgment = preload("res://scripts/systems/judgment.gd")
const ScalesView = preload("res://scripts/ui/widgets/scales_view.gd")

var cid := ""
var case_data: Dictionary
var comp: Dictionary
var selected := ""
var verdict_buttons := {}
var verdict_desc: Label


func _init(p_cid := "") -> void:
	cid = p_cid
	dim = 0.75


func build() -> void:
	case_data = GameData.get_case(cid)
	comp = Judgment.compute(case_data, GameState)
	var soul := GameData.soul(cid)
	var p := framed(30)
	var v := UI.vbox(12)
	p.add_child(v)
	v.add_child(header(Loc.t("jd_title", [soul.name]), "𓆄", Loc.t("jd_subtitle")))
	v.add_child(UI.separator())
	var h := UI.hbox(20)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)

	# bal: mérleg + paraméterek
	var left := UI.vbox(10)
	left.custom_minimum_size.x = T.px(470)
	var scales := ScalesView.new()
	scales.custom_minimum_size = T.v2(460, 230)
	scales.set_balance(comp.balance)
	left.add_child(scales)
	left.add_child(UI.title(Loc.t("jd_thoth_record"), 18, T.GOLD))
	for pd in GameData.temple.get("params", []):
		left.add_child(_param_row(pd, float(comp.params.get(pd.id, 0))))
	h.add_child(left)

	# közép: rekonstrukció
	var mid := UI.papyrus(22)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mv := UI.vbox(10)
	mid.add_child(mv)
	mv.add_child(UI.title(Loc.t("jd_reconstruction"), 22, T.RED_INK))
	for sc in case_data.scenes:
		var r: Dictionary = comp.slots[sc.id]
		var row := UI.vbox(2)
		var rh := UI.hbox(8)
		rh.add_child(UI.title("%s. %s" % [sc.get("numeral", ""), sc.title], 17, T.INK))
		rh.add_child(UI.spacer())
		rh.add_child(UI.state_badge(r.state, 12))
		row.add_child(rh)
		if r.title != "":
			row.add_child(UI.label("„%s” – %s" % [r.title, r.narrative], 14, T.INK_L, true))
		else:
			row.add_child(UI.label(Loc.t("res_no_interp"), 14, T.INK_L, true))
		mv.add_child(row)
	mv.add_child(UI.separator(T.INK_L))
	mv.add_child(UI.label(Loc.t("jd_warning"), 14, T.RED_INK, true))
	h.add_child(UI.scroll(mid))

	# jobb: ítéletek
	var right := UI.vbox(10)
	right.custom_minimum_size.x = T.px(380)
	right.add_child(UI.title(Loc.t("jd_verdicts"), 20, T.GOLD))
	for vd in GameData.temple.get("verdicts", []):
		var b := UI.button("%s   %s" % [vd.glyph, vd.label], _select.bind(str(vd.id)))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 19)
		b.custom_minimum_size.y = T.px(52)
		verdict_buttons[vd.id] = b
		right.add_child(b)
	verdict_desc = UI.label(Loc.t("jd_pick"), 15, T.SAND, true)
	verdict_desc.custom_minimum_size.y = T.px(90)
	right.add_child(verdict_desc)
	h.add_child(right)


func _param_row(pd: Dictionary, val: float) -> Control:
	var row := UI.vbox(2)
	var h := UI.hbox(8)
	h.add_child(UI.glyphs(str(pd.glyph), 20, T.GOLD))
	h.add_child(UI.label(str(pd.label), 16, T.PAPYRUS))
	h.add_child(UI.spacer())
	h.add_child(UI.label(str(int(round(val))), 16, T.GOLD_L))
	row.add_child(h)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = val
	bar.show_percentage = false
	bar.custom_minimum_size.y = T.px(8)
	var fill := T.flat(T.GOLD, Color(0, 0, 0, 0), 0, 3, 0)
	var bg := T.flat(Color(0, 0, 0, 0.45), T.GOLD_D, 1, 3, 0)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	row.add_child(bar)
	row.tooltip_text = str(pd.desc)
	return row


func _select(vid: String) -> void:
	selected = vid
	for k in verdict_buttons:
		var b: Button = verdict_buttons[k]
		if k == vid:
			b.add_theme_stylebox_override("normal", T.flat(Color(T.LAPIS_L, 0.95), T.GOLD_L, 2, 6, 10))
		else:
			b.remove_theme_stylebox_override("normal")
	var vd := GameData.verdict(vid)
	verdict_desc.text = str(vd.get("desc", ""))
	# azonnali megerősítés: mit jelent ez az ítélet a lélek számára
	var soul := GameData.soul(cid)
	var text := Loc.t("jd_confirm_full", [vd.label, soul.get("name", ""), str(vd.get("consequence", ""))])
	main.confirm(text, _do_pronounce, Loc.t("jd_pronounce"), _clear_selection)


func _clear_selection() -> void:
	selected = ""
	for k in verdict_buttons:
		(verdict_buttons[k] as Button).remove_theme_stylebox_override("normal")
	verdict_desc.text = Loc.t("jd_pick")


func _do_pronounce() -> void:
	var result := Judgment.resolve(case_data, selected, GameState)
	if result.is_empty():
		return
	GameState.record_judgment(cid, result)
	GameState.flush()
	main.close_all_overlays()
	main.show_result(cid, result)
