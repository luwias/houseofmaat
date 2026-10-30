extends "res://scripts/ui/widgets/overlay.gd"
## Párbeszéd és kihallgatás egy megidézett ka-val.

const Dlg = preload("res://scripts/systems/dialogue.gd")

var cid := ""
var did := ""
var nid := "start"
var case_data: Dictionary
var dlg: Dictionary
var text_label: RichTextLabel
var options_box: VBoxContainer
var _tw: Tween
## Újrakérdezés: a már elhangzott válaszok visszaidézése, hatások nélkül.
var replay := false


func _init(p_cid := "", p_did := "", p_replay := false) -> void:
	cid = p_cid
	did = p_did
	replay = p_replay
	dim = 0.5


func build() -> void:
	case_data = GameData.get_case(cid)
	dlg = Dlg.get_dialogue(case_data, did)
	var m := UI.margin(null, 120, 0, 120, 60)
	m.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	m.offset_top = -560
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var p := UI.dark_panel(22, 0.96, T.GOLD)
	m.add_child(p)
	var h := UI.hbox(24)
	p.add_child(h)
	# portré
	var port := UI.vbox(8)
	port.custom_minimum_size.x = 210
	var circle := UI.box_panel(T.LAPIS.darkened(0.3), T.GOLD, 3, 10, 90)
	circle.custom_minimum_size = Vector2(170, 170)
	circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var g := UI.glyphs(str(dlg.get("glyph", "𓂓")), 84, T.GOLD_L)
	g.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	circle.add_child(g)
	port.add_child(circle)
	port.add_child(UI.title(str(dlg.get("speaker", "")), 24, T.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	port.add_child(UI.label(str(dlg.get("role", "")), 14, T.SAND, true, HORIZONTAL_ALIGNMENT_CENTER))
	port.add_child(UI.label(Loc.t("dlg_replay_note") if replay else Loc.t("dlg_ka_note"), 12, T.MUTED, true,
		HORIZONTAL_ALIGNMENT_CENTER))
	h.add_child(port)
	var right := UI.vbox(14)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(right)
	text_label = UI.rich("", 20, T.PAPYRUS)
	text_label.custom_minimum_size.y = 150
	text_label.mouse_filter = Control.MOUSE_FILTER_STOP
	text_label.gui_input.connect(_on_text_input)
	right.add_child(text_label)
	right.add_child(UI.separator())
	options_box = UI.vbox(8)
	right.add_child(UI.scroll(options_box))
	if replay:
		_replay_menu()
	else:
		_enter(nid)


func _on_text_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and _tw != null and _tw.is_running():
		_tw.kill()
		text_label.visible_ratio = 1.0


func _enter(node_id: String) -> void:
	nid = node_id
	Dlg.enter(case_data, did, nid, GameState)
	GameState.flush()
	var node := Dlg.node(case_data, did, nid)
	text_label.text = str(node.get("text", ""))
	text_label.visible_ratio = 0.0
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(text_label, "visible_ratio", 1.0, clampf(text_label.text.length() / 90.0, 0.4, 3.0))
	_build_options()


func refresh() -> void:
	pass


func _build_options() -> void:
	UI.clear(options_box)
	for o in Dlg.options(case_data, did, nid, GameState):
		var opt: Dictionary = o.opt
		var txt := str(opt.text)
		var b := UI.button(txt, _choose.bind(int(o.index)))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.x = 600
		b.add_theme_font_size_override("font_size", 17)
		if opt.has("evidence"):
			b.add_theme_stylebox_override("normal", T.flat(Color(T.GOLD_D, 0.45), T.GOLD, 2, 6, 10))
			b.add_theme_color_override("font_color", T.GOLD_L)
		elif opt.has("group"):
			b.add_theme_stylebox_override("normal", T.flat(Color(T.RED, 0.25), T.OCHRE, 2, 6, 10))
		elif str(opt.get("next", "")) == "end":
			b.add_theme_color_override("font_color", T.SAND)
		if opt.has("group"):
			b.tooltip_text = Loc.t("dlg_exclusive")
		options_box.add_child(b)


# ------------------------------------------------------------ újrakérdezés
func _show_text(t: String) -> void:
	text_label.text = t
	text_label.visible_ratio = 0.0
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(text_label, "visible_ratio", 1.0, clampf(t.length() / 120.0, 0.3, 2.0))


func _replay_menu() -> void:
	_show_text(Loc.t("dlg_replay_intro"))
	_build_replay_options("")


func _replay_node(node_id: String, question: String) -> void:
	_show_text("[color=#d4a640][i]%s[/i][/color]

%s" % [question, str(Dlg.node(case_data, did, node_id).get("text", ""))])
	_build_replay_options(node_id)


func _build_replay_options(current: String) -> void:
	UI.clear(options_box)
	for e in Dlg.heard(case_data, did, GameState):
		var b := UI.button("↺  " + str(e.question), _replay_node.bind(str(e.node), str(e.question)))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.x = 600
		b.add_theme_font_size_override("font_size", 16)
		if e.node == current:
			b.add_theme_stylebox_override("normal", T.flat(Color(T.LAPIS_L, 0.95), T.GOLD_L, 2, 6, 10))
		options_box.add_child(b)
	var close_b := UI.button(Loc.t("dlg_replay_close"), close)
	close_b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	close_b.add_theme_color_override("font_color", T.SAND)
	options_box.add_child(close_b)


func _choose(idx: int) -> void:
	var nxt := Dlg.choose(case_data, did, nid, idx, GameState)
	GameState.flush()
	if nxt == "end":
		close()
	else:
		_enter(nxt)
