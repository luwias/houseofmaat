extends "res://scripts/ui/widgets/overlay.gd"
## Megerősítő párbeszédablak.

var text := ""
var on_yes: Callable
var yes_label := ""


func _init(p_text := "", p_on_yes: Callable = Callable(), p_yes := "") -> void:
	text = p_text
	on_yes = p_on_yes
	yes_label = p_yes
	dim = 0.5


func build() -> void:
	var p := centered(Vector2(560, 0))
	var v := UI.vbox(18)
	p.add_child(v)
	v.add_child(UI.glyphs("𓆄", 30, T.GOLD))
	v.add_child(UI.label(text, 19, T.PAPYRUS, true, HORIZONTAL_ALIGNMENT_CENTER))
	var h := UI.hbox(16)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(UI.button(Loc.t("btn_cancel"), close, 140))
	h.add_child(UI.button(yes_label if yes_label != "" else Loc.t("btn_yes"), _yes, 140))
	v.add_child(h)


func _yes() -> void:
	close()
	if on_yes.is_valid():
		on_yes.call()
