extends PanelContainer
## Papiruszlap: rostos shader, sötétedő szélek, belső aranyvonal.

const T = preload("res://scripts/ui/theme.gd")

var _mat: ShaderMaterial


func _init(margin: int = 22) -> void:
	add_theme_stylebox_override("panel", T.flat(T.PAPYRUS, T.GOLD_D, 3, 4, margin))
	_mat = ShaderMaterial.new()
	_mat.shader = T.papyrus_shader
	_mat.set_shader_parameter("seed", randf() * 10.0)
	material = _mat
	resized.connect(_on_resized)


func _on_resized() -> void:
	_mat.set_shader_parameter("rect_size", size)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(7, 7), size - Vector2(14, 14)), Color(T.GOLD_D, 0.5), false, 1.0)
