extends PanelContainer
## Storyboard-kártya két megjelenéssel:
##   tálcán (slot_id == "")  – álló, képes csempe: illusztráció vagy nagy jel, alatta a cím,
##                            a sarokban a kategória színes rombusza
##   jelenetben             – keskeny sor: jel, cím, ✕ gomb
## A bizonyítékkártyák sötét pergamenen, arany jellel különülnek el.

const T = preload("res://scripts/ui/theme.gd")
const UI = preload("res://scripts/ui/ui.gd")
const ArtFrame = preload("res://scripts/ui/widgets/art_frame.gd")
const Fresco = preload("res://scripts/ui/widgets/fresco.gd")

signal clicked(card_id: String)
signal double_clicked(card_id: String)

var card_id := ""
var category := ""
var source_slot := ""
var draggable := true
var top_row: HBoxContainer
var _card: Dictionary = {}
var _cat_color := Color.WHITE
var _tile := true


func setup(card: Dictionary, slot_id: String = "", _compact: bool = false) -> void:
	_card = card
	card_id = card.id
	category = card.category
	source_slot = slot_id
	_tile = slot_id == ""
	tooltip_text = "%s\n%s" % [card.title, card.get("desc", "")]
	mouse_default_cursor_shape = Control.CURSOR_DRAG if draggable else Control.CURSOR_POINTING_HAND
	_cat_color = T.CATEGORY_COLORS.get(category, T.MUTED)
	if category == "evidence":
		_cat_color = T.GOLD
	var is_ev := category == "evidence"
	var bg := Color("2a2118") if is_ev else T.PAPYRUS
	var sb := T.flat(bg, Color(T.GOLD_D, 0.95), 1, 4, 6)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	add_theme_stylebox_override("panel", sb)
	var ink := T.GOLD_L if is_ev else T.INK
	if _tile:
		_build_tile(card, ink)
	else:
		_build_row(card, ink)


func _build_tile(card: Dictionary, ink: Color) -> void:
	custom_minimum_size = Vector2(150, 78) if T.compact else Vector2(104, 124)
	var v := UI.vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	top_row = UI.hbox(2)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.custom_minimum_size.y = 14
	top_row.add_child(UI.spacer())
	v.add_child(top_row)
	var tex := ArtFrame.find("cards", card.id)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.custom_minimum_size = Vector2(0, 26 if T.compact else 62)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tr)
	else:
		var g := UI.glyphs(str(card.get("glyph", "?")), 24 if T.compact else 38, ink)
		g.custom_minimum_size.y = 24 if T.compact else 58
		g.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(g)
	var t := UI.label(card.title, 13, ink, true, HORIZONTAL_ALIGNMENT_CENTER)
	t.add_theme_font_override("font", T.font_body_bold)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)


func _build_row(card: Dictionary, ink: Color) -> void:
	custom_minimum_size = Vector2(0, 40)
	top_row = UI.hbox(6)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_row)
	var g := UI.glyphs(str(card.get("glyph", "?")), 20, ink)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(g)
	var t := UI.label(card.title, 14, ink, true)
	t.add_theme_font_override("font", T.font_body_bold)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(t)


func _draw() -> void:
	# kategóriajelölő rombusz a jobb felső sarokban
	var c := Vector2(size.x - 11, 11) if _tile else Vector2(size.x - 9, size.y * 0.5)
	if not _tile:
		return
	Fresco.diamond(self, c, 5.0, _cat_color, Color(T.BLACK, 0.6))


## Kis ✕ gomb a lehelyezett kártyára (érintőképernyőn a dupla koppintás helyett).
func add_remove_button(cb: Callable) -> void:
	var b := Button.new()
	b.text = "✕"
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	b.tooltip_text = Loc.t("sb_remove")
	b.add_theme_font_size_override("font_size", 18 if T.compact else 14)
	b.add_theme_color_override("font_color", T.RED_INK)
	b.add_theme_color_override("font_hover_color", T.RED)
	b.custom_minimum_size = Vector2(30, 26) if T.compact else Vector2(22, 20)
	b.pressed.connect(cb)
	top_row.add_child(b)


## Darabszám-jelvény (pl. „×3”), ha a kártyából több példány maradt a tálcán.
func set_count(n: int) -> void:
	var b := UI.badge("×%d" % n, T.RED, 11)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(b)
	top_row.move_child(b, 0)
	tooltip_text += "\n" + Loc.t("sb_copies_left", [n])


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if event.double_click:
			double_clicked.emit(card_id)
		else:
			clicked.emit(card_id)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable:
		return null
	var preview := duplicate(0)
	var holder := Control.new()
	holder.add_child(preview)
	preview.position = -custom_minimum_size * 0.5
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(holder)
	return {"type": "card", "id": card_id, "from": source_slot}
