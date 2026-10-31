extends Control
## Főmenü a háttérben lassan forgó Ítélet Csarnokával.

const T = preload("res://scripts/ui/theme.gd")
const UI = preload("res://scripts/ui/ui.gd")
const FriezeStrip = preload("res://scripts/ui/widgets/frieze_strip.gd")

var main: Node


func _init() -> void:
	UI.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(T.DEEP, 0.96))
	grad.set_color(1, Color(T.DEEP, 0.0))
	grad.add_point(0.45, Color(T.DEEP, 0.82))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	var shade := TextureRect.new()
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	shade.offset_right = 1050
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var m := UI.margin(null, int(T.px(110)), int(T.px(90)) - (30 if T.compact else 0), 0, int(T.px(70)))
	m.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	m.offset_right = T.px(900) + (120 if T.compact else 0)
	add_child(m)
	var v := UI.vbox(14)
	m.add_child(v)
	v.add_child(UI.glyphs("𓋹  𓆄  𓂀  𓆄  𓋹", 26, T.GOLD_D, HORIZONTAL_ALIGNMENT_LEFT))
	var t := UI.title("THE HOUSE OF MA'AT", 48 if T.compact else 64, T.GOLD)
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	t.add_theme_constant_override("shadow_offset_y", 3)
	v.add_child(t)
	v.add_child(UI.title(Loc.t("game_title_hu"), 30, T.GOLD_L))
	var strip := FriezeStrip.new(10.0)
	strip.custom_minimum_size.x = T.px(620)
	strip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(strip)
	v.add_child(UI.gap(6))
	var tag := UI.label(Loc.t("menu_tagline"), 20, T.SAND, true)
	tag.custom_minimum_size.x = T.px(640)
	v.add_child(tag)
	v.add_child(UI.gap(10 if T.compact else 28))

	var has_save := GameState.has_save()
	var b_cont := UI.primary_button(Loc.t("menu_continue"), func(): main.continue_game(), 320)
	b_cont.disabled = not has_save
	var b_new := UI.primary_button(Loc.t("menu_new"), _on_new, 320) if not has_save else UI.button(Loc.t("menu_new"), _on_new, 320)
	for b in [b_cont, b_new]:
		b.add_theme_font_size_override("font_size", 22)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if has_save:
		v.add_child(b_cont)
		v.add_child(b_new)
	else:
		v.add_child(b_new)
	var b_help := UI.button(Loc.t("menu_help"), func(): main.open_help(), 320)
	b_help.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(b_help)
	var b_quit := UI.button(Loc.t("menu_quit"), func(): get_tree().quit(), 320)
	b_quit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(b_quit)
	v.add_child(UI.spacer(false))
	v.add_child(UI.label(Loc.t("menu_footer"), 14, T.MUTED))


func _on_new() -> void:
	if GameState.has_save():
		main.confirm(Loc.t("confirm_new_game"), func(): main.new_game(), Loc.t("menu_new"))
	else:
		main.new_game()
