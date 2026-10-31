extends Control
## Vékony, vízszintes színes sávkeret – elválasztóként a fejlécek és tartalom között.

const Fresco = preload("res://scripts/ui/widgets/fresco.gd")

var thickness := 8.0


func _init(p_thickness := 8.0) -> void:
	thickness = p_thickness * 1.4
	custom_minimum_size = Vector2(0, thickness)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	Fresco.band(self, Rect2(Vector2.ZERO, Vector2(size.x, thickness)), true)
