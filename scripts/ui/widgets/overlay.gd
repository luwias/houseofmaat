extends Control
## Átfedő képernyők alaposztálya: elsötétített háttér, bezárás, navigáció a Main felé.

const T = preload("res://scripts/ui/theme.gd")
const UI = preload("res://scripts/ui/ui.gd")

signal closed

var main: Node
var dim := 0.62
var close_on_backdrop := false


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	# az alosztályok paraméteres _init-je miatt itt is kitöltjük a szülőt
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.012, dim)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	UI.full_rect(bg)
	add_child(bg)
	move_child(bg, 0)
	if close_on_backdrop:
		bg.gui_input.connect(_on_backdrop_input)
	build()
	GameState.state_changed.connect(_on_state_changed)


func _on_backdrop_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		close()


## Felülírandó: a képernyő felépítése.
func build() -> void:
	pass


## Felülírandó: állapotváltozáskor frissítés.
func refresh() -> void:
	pass


func _on_state_changed() -> void:
	if is_inside_tree() and visible:
		refresh()


func close() -> void:
	closed.emit()
	queue_free()


## Középre igazított keret adott mérettel; ebbe kerül a tartalom.
func centered(min_size: Vector2, panel: PanelContainer = null) -> PanelContainer:
	var cc := CenterContainer.new()
	UI.full_rect(cc)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	var p := panel if panel != null else UI.dark_panel(22, 0.94, T.GOLD_D, true)
	var want := T.v2(min_size.x, min_size.y)
	var avail := get_viewport().get_visible_rect().size - Vector2(24, 24) if is_inside_tree() else want
	p.custom_minimum_size = Vector2(minf(want.x, avail.x), minf(want.y, avail.y))
	cc.add_child(p)
	return p


## Teljes képernyős keret margóval.
func framed(margin_px: int = 36, panel: PanelContainer = null) -> PanelContainer:
	margin_px = int(T.px(margin_px)) if T.compact else margin_px
	if T.compact:
		margin_px = mini(margin_px, 10)
	var m := UI.margin(null, margin_px, margin_px, margin_px, margin_px)
	UI.full_rect(m)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var p := panel if panel != null else UI.dark_panel(20, 0.94, T.GOLD_D, not T.compact)
	m.add_child(p)
	return p


## Fejléc címmel és bezárógombbal.
func header(title_text: String, glyph: String = "𓆄", subtitle: String = "") -> HBoxContainer:
	var h := UI.hbox(14)
	h.add_child(UI.glyphs(glyph, 38, T.GOLD))
	var tv := UI.vbox(0)
	tv.add_child(UI.title(title_text, 28))
	if subtitle != "":
		tv.add_child(UI.label(subtitle, 15, T.SAND))
	h.add_child(tv)
	h.add_child(UI.spacer())
	h.add_child(UI.button(Loc.t("btn_close") + "  ✕", close))
	return h
