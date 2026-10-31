extends PanelContainer
## Festett panel három változatban:
##   "papyrus" – krém papirusz rostokkal, fekete–vörös kettős tintavonallal (dokumentumok)
##   "night"   – csillagos, mélykék sírmennyezet színes sávkerettel (ablakok, párbeszéd)
##   "plaster" – meszelt vakolat színes sávkerettel
## A festék szemcséjét a papirusz-shader adja.

const T = preload("res://scripts/ui/theme.gd")
const Fresco = preload("res://scripts/ui/widgets/fresco.gd")

var kind := "papyrus"
var with_kheker := false
var band := 15.0
var _mat: ShaderMaterial
var _seed := 0


func _init(margin: int = 22, p_kind := "papyrus", p_kheker := false) -> void:
	kind = p_kind
	with_kheker = p_kheker
	_seed = randi()
	if T.compact:
		band = 10.0
	var bg := T.PAPYRUS
	match kind:
		"night":
			bg = T.NAVY
		"plaster":
			bg = Color("e9d7ae")
	var extra := 0.0
	if kind != "papyrus":
		extra = band + 2.0
	var sb := T.flat(bg, T.BLACK, 0 if kind != "papyrus" else 2, 2, margin)
	sb.content_margin_left = margin + extra
	sb.content_margin_right = margin + extra
	sb.content_margin_bottom = margin + extra
	sb.content_margin_top = margin + extra + (34.0 if with_kheker else 0.0)
	add_theme_stylebox_override("panel", sb)
	_mat = ShaderMaterial.new()
	_mat.shader = T.papyrus_shader
	_mat.set_shader_parameter("seed", randf() * 10.0)
	_mat.set_shader_parameter("edge_dark", 0.32 if kind == "papyrus" else 0.12)
	_mat.set_shader_parameter("fiber", 1.0 if kind == "papyrus" else 0.45)
	material = _mat
	resized.connect(_on_resized)


func _on_resized() -> void:
	_mat.set_shader_parameter("rect_size", size)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if kind == "papyrus":
		Fresco.ink_rules(self, r)
		return
	if kind == "night":
		Fresco.stars(self, r.grow(-band - 4), _seed, 0.00010)
	Fresco.frame(self, r, band)
	if with_kheker:
		Fresco.kheker(self, Rect2(band, band, size.x - 2 * band, 34))
