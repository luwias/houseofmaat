extends Control
## Arany díszvonal elválasztóként (széleken elhalványul, középen rombusz).

const Fresco = preload("res://scripts/ui/widgets/fresco.gd")


func _init(_thickness := 8.0) -> void:
	custom_minimum_size = Vector2(0, 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	Fresco.ornament_line(self, Rect2(Vector2.ZERO, size))
