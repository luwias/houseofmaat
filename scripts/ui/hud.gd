extends Control
## Templom-HUD: felül a Ma'at / Ankh / Duat mérők, alul a termek, középen a terem állapota.

const T = preload("res://scripts/ui/theme.gd")
const UI = preload("res://scripts/ui/ui.gd")
const Meter = preload("res://scripts/ui/widgets/meter.gd")
const FriezeStrip = preload("res://scripts/ui/widgets/frieze_strip.gd")

const ROOM_ORDER := ["hall", "archive", "memories", "garden", "hieroglyphs", "forgotten", "astral"]

var main: Node
var m_maat: Control
var m_ankh: Control
var m_duat: Control
var room_title: Label
var room_desc: Label
var room_state: Label
var hover_label: Label
var room_buttons := {}
var active_case_btn: Button
var current_room := "hall"


func _init() -> void:
	UI.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	# felső sáv
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", _bar_style(true))
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 70
	add_child(top)
	var top_band := FriezeStrip.new(9.0)
	top_band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_band.offset_top = 70
	top_band.offset_bottom = 79
	add_child(top_band)
	var th := UI.hbox(22)
	top.add_child(th)
	th.add_child(UI.glyphs("𓆄", 32, T.GOLD))
	var tv := UI.vbox(-2)
	if not T.compact:
		tv.add_child(UI.title(Loc.t("game_title_hu"), 20, T.GOLD))
	room_title = UI.label("", 14, T.SAND)
	if T.compact:
		room_title = UI.title("", 17, T.GOLD)
	tv.add_child(room_title)
	th.add_child(tv)
	if T.compact:
		th.add_theme_constant_override("separation", 10)
	th.add_child(UI.spacer())
	m_maat = Meter.new()
	m_maat.setup("Ma'at", "𓆄", T.GOLD)
	m_maat.tooltip_text = Loc.t("tip_maat")
	th.add_child(m_maat)
	m_ankh = Meter.new()
	m_ankh.setup("Ankh", "𓋹", T.ANKH)
	m_ankh.tooltip_text = Loc.t("tip_ankh")
	th.add_child(m_ankh)
	m_duat = Meter.new()
	m_duat.setup("Duat", "𓇽", T.DUAT, true)
	m_duat.tooltip_text = Loc.t("tip_duat")
	th.add_child(m_duat)
	th.add_child(UI.spacer())
	active_case_btn = UI.button("", _open_active_case)
	th.add_child(active_case_btn)
	var c := T.compact
	th.add_child(_top_btn("𓁹" if c else Loc.t("btn_souls"), func(): main.open_soul_board()))
	th.add_child(_top_btn("𓏞" if c else Loc.t("btn_archive"), func(): main.open_room_screen("archive", "evidence")))
	th.add_child(_top_btn("✎" if c else Loc.t("btn_notes"), func(): main.open_notes()))
	th.add_child(_top_btn("?", func(): main.open_help()))
	th.add_child(_top_btn("☰" if c else Loc.t("btn_menu"), func(): main.confirm(Loc.t("confirm_to_menu"), main.show_menu)))

	# terem-leírás
	var info := UI.vbox(2)
	info.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	info.offset_left = 28
	info.offset_bottom = -96
	info.offset_top = -200
	info.offset_right = T.px(760)
	info.visible = not T.compact
	info.grow_vertical = Control.GROW_DIRECTION_BEGIN
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info)
	room_desc = UI.title("", 30, T.GOLD_L)
	room_desc.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	room_desc.add_theme_constant_override("shadow_offset_x", 2)
	room_desc.add_theme_constant_override("shadow_offset_y", 2)
	info.add_child(room_desc)
	room_state = UI.label("", 17, T.PAPYRUS, true)
	room_state.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	room_state.add_theme_constant_override("shadow_offset_x", 1)
	room_state.add_theme_constant_override("shadow_offset_y", 1)
	room_state.custom_minimum_size.x = T.px(700)
	info.add_child(room_state)

	# rámutatás
	hover_label = UI.title("", 22, T.GOLD_L, HORIZONTAL_ALIGNMENT_CENTER)
	hover_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	hover_label.offset_top = 92
	hover_label.offset_left = -400
	hover_label.offset_right = 400
	hover_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	hover_label.add_theme_constant_override("shadow_offset_x", 2)
	hover_label.add_theme_constant_override("shadow_offset_y", 2)
	hover_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hover_label)

	# alsó terem-navigáció
	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", _bar_style(false))
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -78
	add_child(bottom)
	var bottom_band := FriezeStrip.new(9.0)
	bottom_band.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_band.offset_top = -87
	bottom_band.offset_bottom = -78
	add_child(bottom_band)
	var bh := UI.hbox(8)
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(bh)
	for rid in ROOM_ORDER:
		var r := GameData.room(rid)
		var b := UI.button("%s  %s" % [r.get("glyph", ""), r.get("name", rid)])
		b.add_theme_font_size_override("font_size", 22 if T.compact else 15)
		if T.compact:
			b.custom_minimum_size = Vector2(72, 52)
		b.pressed.connect(func(): main.go_room(rid))
		room_buttons[rid] = b
		bh.add_child(b)
	update_meters(false)
	refresh()


func _top_btn(text: String, cb: Callable) -> Button:
	var b := UI.button(text, cb)
	if T.compact:
		b.add_theme_font_size_override("font_size", 24)
		b.custom_minimum_size = Vector2(56, 50)
		b.add_theme_font_override("font", T.font_glyph)
	return b


func _open_active_case() -> void:
	var cid := str(GameState.data.active_case)
	if cid != "":
		main.open_case(cid)


func _bar_style(_top: bool) -> StyleBoxFlat:
	var s := T.flat(Color(T.NAVY, 0.94), T.BLACK, 0, 0, 12)
	s.content_margin_left = 22
	s.content_margin_right = 22
	return s


func update_meters(animate: bool) -> void:
	m_maat.set_value(GameState.get_stat("maat"), animate)
	m_ankh.set_value(GameState.get_stat("ankh"), animate)
	m_duat.set_value(GameState.get_stat("duat"), animate)


func set_room(rid: String) -> void:
	current_room = rid
	refresh()


func set_hover(text: String) -> void:
	if hover_label:
		hover_label.text = text


func refresh() -> void:
	if room_title == null:
		return
	var r := GameData.room(current_room)
	room_title.text = r.get("name", "")
	room_desc.text = r.get("name", "")
	room_state.text = "%s\n%s" % [r.get("purpose", ""), GameState.room_state_text(current_room)]
	for rid in room_buttons:
		var b: Button = room_buttons[rid]
		var st := GameState.room_status(rid)
		var rr := GameData.room(rid)
		b.disabled = not st.open
		if T.compact:
			b.text = "🔒" if not st.open else str(rr.get("glyph", ""))
		else:
			b.text = "%s  %s" % ["🔒" if not st.open else str(rr.get("glyph", "")), rr.get("name", rid)]
		b.tooltip_text = str(rr.get("purpose", "")) if st.open else str(st.reason)
		var cur: bool = rid == current_room
		b.add_theme_color_override("font_color", T.GOLD_L if cur else T.PAPYRUS)
		if cur:
			b.add_theme_stylebox_override("normal", T.tablet("selected"))
		else:
			b.remove_theme_stylebox_override("normal")
	var cid := str(GameState.data.get("active_case", ""))
	active_case_btn.visible = cid != "" and not GameState.case_done(cid)
	if active_case_btn.visible:
		var s := GameData.soul(cid)
		active_case_btn.text = "%s  %s" % [s.get("glyph", ""), Loc.t("btn_active_case", [s.get("name", cid)])]
