extends PanelContainer
## Panelek két fő változatban:
##   "night"   – mély navy színátmenet, vékony arany kettős keret díszített sarkokkal (ablakok)
##   "papyrus" – meleg pergamen finom rostokkal és arany szegéllyel (dokumentumok, kártyák)
## A korábbi "plaster" változat a pergamenre esik vissza.

const T = preload("res://scripts/ui/theme.gd")
const Fresco = preload("res://scripts/ui/widgets/fresco.gd")

var kind := "papyrus"
var _mat: ShaderMaterial


func _init(margin: int = 22, p_kind := "papyrus", _unused := false) -> void:
	kind = "night" if p_kind == "night" else "papyrus"
	var m := float(margin) + (8.0 if kind == "night" else 4.0)
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = m
	sb.content_margin_right = m
	sb.content_margin_top = m
	sb.content_margin_bottom = m
	if kind == "papyrus":
		var flat := T.flat(T.PAPYRUS, Color(0, 0, 0, 0), 0, 3, margin)
		flat.content_margin_left = m
		flat.content_margin_right = m
		flat.content_margin_top = m
		flat.content_margin_bottom = m
		add_theme_stylebox_override("panel", flat)
		_mat = ShaderMaterial.new()
		_mat.shader = T.papyrus_shader
		_mat.set_shader_parameter("seed", randf() * 10.0)
		_mat.set_shader_parameter("edge_dark", 0.28)
		_mat.set_shader_parameter("fiber", 0.7)
		material = _mat
	else:
		add_theme_stylebox_override("panel", sb)
	resized.connect(_on_resized)


func _on_resized() -> void:
	if _mat:
		_mat.set_shader_parameter("rect_size", size)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if kind == "night":
		Fresco.gradient(self, r, Color("17213a"), Color("0b1020"))
		draw_rect(r, Color(0, 0, 0, 0.6), false, 2.0)
		Fresco.gold_frame(self, r, 3.0, true)
	else:
		draw_rect(r.grow(-1), Color(T.GOLD_D, 0.9), false, 2.0)
		draw_rect(r.grow(-5), Color(T.GOLD_D, 0.45), false, 1.0)
