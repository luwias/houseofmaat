extends "res://scripts/ui/widgets/overlay.gd"
## Két bizonyíték egymás melletti összevetése. Egyes párok új felfedezést hoznak.

var cid := ""
var pre := ""
var case_data: Dictionary
var lists := []
var previews := []
var result_box: VBoxContainer
var ids := []


func _init(p_cid := "", p_pre := "") -> void:
	cid = p_cid
	pre = p_pre


func build() -> void:
	case_data = GameData.get_case(cid)
	var p := centered(Vector2(1320, 780))
	var v := UI.vbox(12)
	p.add_child(v)
	v.add_child(header(Loc.t("cmp_title"), "𓂀", Loc.t("cmp_subtitle")))
	v.add_child(UI.separator())
	for ev in case_data.evidence:
		if GameState.has_evidence(ev.id):
			ids.append(ev.id)
	var h := UI.hbox(16)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(h)
	for side in 2:
		var col := UI.vbox(8)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ob := OptionButton.new()
		ob.focus_mode = Control.FOCUS_NONE
		for id in ids:
			ob.add_item("%s – %s" % [id, GameData.evidence(id).title])
		col.add_child(ob)
		var prev := UI.papyrus(18)
		prev.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(prev)
		lists.append(ob)
		previews.append(prev)
		ob.item_selected.connect(func(_i): _update_preview(side))
		h.add_child(col)
		if side == 0:
			var mid := UI.vbox(10)
			mid.alignment = BoxContainer.ALIGNMENT_CENTER
			mid.add_child(UI.glyphs("𓆄", 40, T.GOLD))
			mid.add_child(UI.button(Loc.t("cmp_do"), _compare, 160))
			h.add_child(mid)
	var a_idx := ids.find(pre) if pre != "" else 0
	lists[0].select(maxi(a_idx, 0))
	lists[1].select(1 if ids.size() > 1 and a_idx != 1 else 0)
	_update_preview(0)
	_update_preview(1)
	result_box = UI.vbox(6)
	var rp := UI.box_panel(Color(T.DEEP, 0.7), T.GOLD_D, 1, 14)
	rp.custom_minimum_size.y = 120
	rp.add_child(result_box)
	v.add_child(rp)
	result_box.add_child(UI.label(Loc.t("cmp_help"), 15, T.SAND, true))


func _update_preview(side: int) -> void:
	var prev: PanelContainer = previews[side]
	UI.clear(prev)
	if ids.is_empty():
		return
	var id: String = ids[lists[side].selected]
	var ev := GameData.evidence(id)
	var pv := UI.vbox(8)
	pv.add_child(UI.title(ev.title, 22, T.RED_INK))
	pv.add_child(UI.label(UI.reliability_text(GameState.get_reliability(id)), 13, T.INK_L))
	pv.add_child(UI.rich("[i]%s[/i]" % GameState.evidence_text(id), 16))
	prev.add_child(UI.scroll(pv))


func _compare() -> void:
	if ids.size() < 2:
		return
	var a: String = ids[lists[0].selected]
	var b: String = ids[lists[1].selected]
	UI.clear(result_box)
	if a == b:
		result_box.add_child(UI.label(Loc.t("cmp_same"), 16, T.SAND, true))
		return
	var res := GameState.compare_evidence(cid, a, b)
	GameState.flush()
	var col := T.GOLD_L if res.found else T.SAND
	result_box.add_child(UI.title(Loc.t("cmp_found") if res.found else Loc.t("cmp_none_title"), 18, col))
	result_box.add_child(UI.label(str(res.text), 17, T.PAPYRUS, true))
	for i in 2:
		_update_preview(i)
