extends "res://scripts/ui/widgets/overlay.gd"
## Bevezető és játékszabályok.

var intro := false


func _init(p_intro := false) -> void:
	intro = p_intro


func build() -> void:
	var p := centered(Vector2(980, 720), UI.papyrus(34))
	var v := UI.vbox(12)
	p.add_child(v)
	v.add_child(UI.ornament(T.GOLD_D, 18))
	v.add_child(UI.title(Loc.t("help_title_intro") if intro else Loc.t("help_title"), 32, T.RED_INK,
		HORIZONTAL_ALIGNMENT_CENTER))
	var body := UI.vbox(10)
	if intro:
		body.add_child(UI.rich(Loc.t("help_intro_text"), 19))
		body.add_child(UI.separator(T.INK_L))
	body.add_child(UI.rich(Loc.t("help_text"), 17))
	var sc := UI.scroll(body)
	sc.custom_minimum_size.y = 520
	v.add_child(sc)
	var h := UI.hbox()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(UI.ink_button(Loc.t("help_start") if intro else Loc.t("btn_close"), close))
	v.add_child(h)
