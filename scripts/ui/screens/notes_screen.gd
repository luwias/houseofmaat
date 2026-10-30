extends "res://scripts/ui/widgets/overlay.gd"
## Az Őrző jegyzetfüzete: a játékos saját, kézzel írt jegyzetei.
## Egy általános lap és lelkenként egy lap; minden automatikusan mentődik.

var page := "general"
var editor: TextEdit
var page_buttons := {}
var title_label: Label


func _init(p_page := "") -> void:
	if p_page != "":
		page = p_page
	dim = 0.55


func build() -> void:
	var p := centered(Vector2(1180, 780), UI.papyrus(30))
	var v := UI.vbox(12)
	p.add_child(v)
	var h := UI.hbox(12)
	h.add_child(UI.glyphs("𓏞", 34, T.RED_INK))
	h.add_child(UI.title(Loc.t("notes_title"), 30, T.RED_INK))
	h.add_child(UI.spacer())
	h.add_child(UI.ink_button(Loc.t("btn_close") + "  ✕", close))
	v.add_child(h)
	v.add_child(UI.label(Loc.t("notes_hint"), 14, T.INK_L, true))
	var body := UI.hbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	var tabs := UI.vbox(8)
	tabs.custom_minimum_size.x = 220
	body.add_child(tabs)
	_add_page_button(tabs, "general", "𓆄", Loc.t("notes_general"))
	for s in GameData.souls:
		if GameData.cases.has(s.id) and GameState.case_state(s.id).get("status", "new") != "new":
			_add_page_button(tabs, s.id, str(s.glyph), "%s, %s" % [s.name, s.epithet])
	if not page_buttons.has(page):
		page = "general"
	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	title_label = UI.title("", 20, T.INK)
	right.add_child(title_label)
	editor = TextEdit.new()
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.placeholder_text = Loc.t("notes_placeholder")
	editor.add_theme_font_size_override("font_size", 19)
	editor.add_theme_color_override("font_color", T.INK)
	editor.add_theme_color_override("font_placeholder_color", Color(T.INK_L, 0.55))
	editor.add_theme_color_override("caret_color", T.RED_INK)
	editor.add_theme_color_override("selection_color", Color(T.GOLD, 0.45))
	editor.add_theme_color_override("font_selected_color", T.INK)
	var lined := T.flat(Color(1, 1, 1, 0.18), Color(T.INK_L, 0.45), 1, 4, 14)
	editor.add_theme_stylebox_override("normal", lined)
	editor.add_theme_stylebox_override("focus", T.flat(Color(1, 1, 1, 0.24), T.GOLD_D, 1, 4, 14))
	editor.text_changed.connect(_on_text_changed)
	right.add_child(editor)
	_show_page()


func _add_page_button(parent: Control, key: String, glyph: String, text: String) -> void:
	var b := UI.ink_button("%s  %s" % [glyph, text], _select_page.bind(key))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	page_buttons[key] = b
	parent.add_child(b)


func _select_page(key: String) -> void:
	page = key
	_show_page()


func _show_page() -> void:
	for k in page_buttons:
		var b: Button = page_buttons[k]
		b.add_theme_color_override("font_color", T.RED_INK if k == page else T.INK)
	var soul := GameData.soul(page)
	title_label.text = Loc.t("notes_general") if soul.is_empty() else "%s, %s" % [soul.name, soul.epithet]
	editor.text = GameState.get_note(page)
	editor.set_caret_line(editor.get_line_count() - 1)
	editor.set_caret_column(editor.get_line(editor.get_line_count() - 1).length())
	editor.grab_focus()


func _on_text_changed() -> void:
	GameState.set_note(page, editor.text)


func close() -> void:
	GameState.set_note(page, editor.text)
	GameState.flush()
	super.close()
