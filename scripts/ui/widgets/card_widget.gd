extends PanelContainer
## Egy storyboard-kártya (szereplő, esemény, tárgy, helyszín, emlék vagy bizonyíték).
## Húzható; a bizonyítékkártyák vizuálisan elkülönülnek (sötét lapis, aranypecsét).

const T = preload("res://scripts/ui/theme.gd")
const UI = preload("res://scripts/ui/ui.gd")

signal clicked(card_id: String)
signal double_clicked(card_id: String)

var card_id := ""
var category := ""
var source_slot := ""
var draggable := true
var _card: Dictionary = {}


func setup(card: Dictionary, slot_id: String = "", compact: bool = false) -> void:
	_card = card
	card_id = card.id
	category = card.category
	source_slot = slot_id
	tooltip_text = "%s\n%s" % [card.title, card.get("desc", "")]
	mouse_default_cursor_shape = Control.CURSOR_DRAG if draggable else Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(118, 74) if compact else Vector2(132, 88)
	var col: Color = T.CATEGORY_COLORS.get(category, T.MUTED)
	var is_ev := category == "evidence"
	var bg := Color(T.LAPIS.darkened(0.35), 0.98) if is_ev else T.PAPYRUS
	var border := T.GOLD if is_ev else col.darkened(0.15)
	var sb := T.flat(bg, border, 2, 5, 6)
	sb.border_width_top = 6 if not is_ev else 2
	add_theme_stylebox_override("panel", sb)

	var v := UI.vbox(1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	var top := UI.hbox(4)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)
	var g := UI.glyphs(str(card.get("glyph", "?")), 22 if not compact else 18, T.GOLD if is_ev else col.darkened(0.3))
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(g)
	top.add_child(UI.spacer())
	var cap := UI.label(card.id if is_ev else Loc.t("cat_" + category), 11, T.GOLD_L if is_ev else T.INK_L)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(cap)
	var t := UI.label(card.title, 15 if not compact else 13, T.PAPYRUS if is_ev else T.INK, true)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_theme_font_override("font", T.font_title)
	v.add_child(t)


## Kis ✕ gomb a lehelyezett kártyára (érintőképernyőn a dupla koppintás helyett).
func add_remove_button(cb: Callable) -> void:
	var b := Button.new()
	b.text = "✕"
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	b.tooltip_text = Loc.t("sb_remove")
	b.add_theme_font_size_override("font_size", 18 if T.compact else 13)
	b.add_theme_color_override("font_color", T.RED_INK)
	b.add_theme_color_override("font_hover_color", T.RED)
	b.custom_minimum_size = Vector2(30, 26) if T.compact else Vector2(20, 18)
	b.pressed.connect(cb)
	var top: Control = get_child(0).get_child(0)
	top.add_child(b)


## Darabszám-jelvény (pl. „×3”), ha a kártyából több példány maradt a tálcán.
func set_count(n: int) -> void:
	var b := UI.badge("×%d" % n, T.RED_INK, 12)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.tooltip_text = ""
	var top: Control = get_child(0).get_child(0)
	top.add_child(b)
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
