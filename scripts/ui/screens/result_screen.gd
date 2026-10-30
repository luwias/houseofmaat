extends "res://scripts/ui/widgets/overlay.gd"
## Az ítélet eredménye: befejezés, kategória, magyarázat, templom-hatások.

var cid := ""
var result: Dictionary
var replay := false


func _init(p_cid := "", p_result: Dictionary = {}, p_replay := false) -> void:
	cid = p_cid
	result = p_result
	replay = p_replay
	dim = 0.82


func build() -> void:
	var cat := GameData.category(str(result.get("category", "")))
	var col := Color(str(cat.get("color", "d4a640")))
	var p := centered(Vector2(1240, 820))
	var v := UI.vbox(12)
	p.add_child(v)
	v.add_child(UI.ornament(T.GOLD_D, 18))
	var th := UI.hbox(14)
	th.alignment = BoxContainer.ALIGNMENT_CENTER
	th.add_child(UI.title(str(result.get("title", "")), 40, T.GOLD))
	v.add_child(th)
	var bh := UI.hbox(12)
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_child(UI.badge(str(cat.get("label", "")), col, 17))
	bh.add_child(UI.label("→  " + GameData.destination_label(str(result.get("destination", ""))), 18, T.SAND))
	v.add_child(bh)
	var h := UI.hbox(18)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	var paper := UI.papyrus(28)
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pv := UI.vbox(12)
	pv.add_child(UI.rich(str(result.get("narrative", "")), 18))
	pv.add_child(UI.separator(T.INK_L))
	pv.add_child(UI.title(Loc.t("res_why"), 20, T.RED_INK))
	pv.add_child(UI.ink(str(cat.get("desc", "")), 16))
	for line in result.get("explain", []):
		pv.add_child(UI.ink("• " + str(line), 16))
	pv.add_child(UI.title(Loc.t("res_reconstruction"), 18, T.RED_INK))
	for r in result.get("reconstruction", []):
		var rh := UI.hbox(8)
		rh.add_child(UI.label("%s – „%s”" % [r.scene, r.title], 15, T.INK, true))
		rh.add_child(UI.state_badge(str(r.state), 12))
		pv.add_child(rh)
	_ideal_section(pv)
	paper.add_child(UI.scroll(pv))
	h.add_child(paper)

	var side := UI.vbox(10)
	side.custom_minimum_size.x = T.px(330)
	side.add_child(UI.title(Loc.t("res_params"), 18, T.GOLD))
	var params: Dictionary = result.get("params", {})
	for pd in GameData.temple.get("params", []):
		var row := UI.hbox(8)
		row.add_child(UI.glyphs(str(pd.glyph), 18, T.GOLD))
		row.add_child(UI.label(str(pd.label), 15, T.PAPYRUS))
		row.add_child(UI.spacer())
		row.add_child(UI.label(str(int(round(float(params.get(pd.id, 0))))), 15, T.GOLD_L))
		side.add_child(row)
	side.add_child(UI.separator())
	side.add_child(UI.title(Loc.t("res_temple"), 18, T.GOLD))
	var eff: Dictionary = cat.get("effects", {})
	for k in ["maat", "ankh", "duat"]:
		var d := int(eff.get(k, 0))
		var good: bool = (d > 0) != (k == "duat")
		var c := T.ANKH if good else T.RED
		if d == 0:
			c = T.SAND
		side.add_child(UI.label("%s   %s%d" % [Loc.t("stat_" + k), "+" if d > 0 else "", d], 17, c))
	side.add_child(UI.label(Loc.t("res_temple_note"), 13, T.SAND, true))
	side.add_child(UI.spacer(false))
	if replay:
		side.add_child(UI.button(Loc.t("btn_close"), close))
	else:
		var b := UI.button(Loc.t("res_return"), func(): main.return_to_hall_after_judgment())
		b.add_theme_font_size_override("font_size", 19)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		side.add_child(b)
	h.add_child(side)


## „Mit kellett volna választanod?” – a helyes ítélet, indoklással és a valódi történettel.
func _ideal_section(pv: VBoxContainer) -> void:
	var case_data := GameData.get_case(cid)
	var ideal: Dictionary = case_data.get("ideal", {})
	if ideal.is_empty():
		return
	pv.add_child(UI.separator(T.INK_L))
	pv.add_child(UI.title(Loc.t("res_ideal_title"), 22, T.RED_INK))
	var good: Array = ideal.get("verdicts", [])
	var just := str(result.get("category", "")).begins_with("just_")
	var verdict := str(result.get("verdict", ""))
	if just:
		pv.add_child(UI.rich("[color=#2f6f45][b]✓ %s[/b][/color]" % Loc.t("res_ideal_right",
			[GameData.verdict(verdict).get("label", verdict)]), 17))
	else:
		var names := []
		for v in good:
			names.append("„%s”" % GameData.verdict(str(v)).get("label", v))
		pv.add_child(UI.rich("[color=#8a2a14][b]✗ %s[/b][/color]" % Loc.t("res_ideal_wrong",
			[Loc.t("res_ideal_or").join(names)]), 17))
	pv.add_child(UI.rich(str(ideal.get("text", "")), 16))
	# a valódi történet jelenetenként, a játékos változatával összevetve
	pv.add_child(UI.title(Loc.t("res_ideal_story"), 17, T.RED_INK))
	var mine := {}
	for r in result.get("reconstruction", []):
		mine[str(r.get("scene_id", ""))] = r
	for sc in case_data.get("scenes", []):
		var best: Dictionary = {}
		for it in sc.get("interpretations", []):
			if best.is_empty() or float(it.get("truth", 0)) > float(best.get("truth", 0)):
				best = it
		var r: Dictionary = mine.get(str(sc.id), {})
		var hit := str(r.get("interp", "")) == str(best.get("id", ""))
		var line := "[b]%s. %s:[/b] „%s” – %s" % [sc.get("numeral", ""), sc.title, best.get("title", ""),
			best.get("narrative", "")]
		if hit:
			line = "[color=#2f6f45]✓[/color] " + line
		else:
			line = "[color=#8a2a14]✗[/color] " + line
			if not r.is_empty():
				line += "\n[i][color=#6a5030](%s)[/color][/i]" % Loc.t("res_ideal_yours", [r.get("title", "")])
		pv.add_child(UI.rich(line, 15))
	var keys: Array = ideal.get("keys", [])
	if not keys.is_empty():
		pv.add_child(UI.title(Loc.t("res_ideal_keys"), 17, T.RED_INK))
		for k in keys:
			pv.add_child(UI.ink("• " + str(k), 15))
