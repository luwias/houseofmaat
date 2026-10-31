extends PanelContainer
## Bizonyíték-csempe az archívumokban: lapis keret, pecsét, megbízhatóság, „ÚJ” jelzés.

const T = preload("res://scripts/ui/theme.gd")
const UI = preload("res://scripts/ui/ui.gd")

signal pressed(eid: String)

var eid := ""


func setup(p_eid: String) -> void:
	eid = p_eid
	var ev := GameData.evidence(eid)
	var corrupted := GameState.is_corrupted(eid)
	custom_minimum_size = T.v2(200, 128)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var border := T.DUAT if corrupted else T.BLACK
	var sb := T.flat(Color("2b2016"), border, 2, 2, 10)
	sb.content_margin_top = 14
	add_theme_stylebox_override("panel", sb)
	tooltip_text = ev.get("description", "")
	var v := UI.vbox(3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	var top := UI.hbox(6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	top.add_child(UI.glyphs(GameData.card(eid).get("glyph", "𓏞"), 24, T.GOLD))
	top.add_child(UI.label(eid, 13, T.GOLD_L))
	top.add_child(UI.spacer())
	if not GameState.is_inspected(eid):
		top.add_child(UI.badge(Loc.t("tag_new"), T.TURQ, 11))
	if corrupted:
		top.add_child(UI.badge(Loc.t("tag_corrupted"), T.DUAT, 11))
	var t := UI.title(ev.get("title", eid), 17, T.PAPYRUS)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	v.add_child(UI.label(Loc.t("type_" + str(ev.get("type", "document"))), 13, T.SAND))
	v.add_child(UI.label(UI.reliability_text(GameState.get_reliability(eid)), 12, T.GOLD_L))
	for c in v.get_children():
		if c is Control:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	# vörös pecsétsáv a tekercs tetején
	draw_rect(Rect2(2, 2, size.x - 4, 6), T.RED)
	draw_line(Vector2(2, 8.5), Vector2(size.x - 2, 8.5), T.BLACK, 1.0)
	draw_circle(Vector2(size.x - 18, 16), 6, T.RED_INK)
	draw_arc(Vector2(size.x - 18, 16), 6, 0, TAU, 16, T.BLACK, 1.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(eid)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		modulate = Color(1.15, 1.1, 1.0)
	elif what == NOTIFICATION_MOUSE_EXIT:
		modulate = Color.WHITE
