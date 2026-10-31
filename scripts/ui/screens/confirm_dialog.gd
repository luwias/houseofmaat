extends "res://scripts/ui/widgets/overlay.gd"
## Megerősítő párbeszédablak.

var text := ""
var on_yes: Callable
var yes_label := ""
var on_no: Callable


func _init(p_text := "", p_on_yes: Callable = Callable(), p_yes := "", p_on_no: Callable = Callable()) -> void:
	text = p_text
	on_yes = p_on_yes
	yes_label = p_yes
	on_no = p_on_no
	dim = 0.5
	backdrop_art = false


func build() -> void:
	var p := centered(Vector2(720 if text.length() > 120 else 560, 0))
	var v := UI.vbox(18)
	p.add_child(v)
	v.add_child(UI.glyphs("𓆄", 30, T.GOLD))
	var body := UI.rich("[center]%s[/center]" % text, 19, T.PAPYRUS)
	v.add_child(body)
	var h := UI.hbox(16)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(UI.button(Loc.t("btn_cancel"), _no, 140))
	h.add_child(UI.button(yes_label if yes_label != "" else Loc.t("btn_yes"), _yes, 140))
	v.add_child(h)


func _no() -> void:
	close()
	if on_no.is_valid():
		on_no.call()


func _yes() -> void:
	close()
	if on_yes.is_valid():
		on_yes.call()
