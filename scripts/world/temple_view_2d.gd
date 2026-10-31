extends Node
## A templom festett, térhatású változata. Ugyanazt a felületet adja, mint a 3D templom
## (go_to_room, set_values, set_progress, interact jelzés …), így a Main bármelyiket használhatja.
## Kamránként egy festett kép (assets/art/rooms/room_<id>.png) és egy mélységtérkép
## (room_<id>_depth.png): az egér (telefonon a döntés) és egy lassú kamerakúszás mozgatja.

const T = preload("res://scripts/ui/theme.gd")
const Fresco = preload("res://scripts/ui/widgets/fresco.gd")
const SHADER = preload("res://shaders/room_parallax.gdshader")
const DIR := "res://assets/art/rooms/"

signal interact(id: String, room: String)
signal hover_changed(id: String, room: String)

## Kattintható helyek a képen, a kép méretéhez viszonyítva (x, y, szélesség, magasság).
const SPOTS := {
	"hall": [["scales", Rect2(0.44, 0.33, 0.12, 0.30)]],
	"archive": [["shelves", Rect2(0.0, 0.05, 0.13, 0.72)], ["shelves", Rect2(0.87, 0.05, 0.13, 0.72)],
		["table", Rect2(0.29, 0.77, 0.42, 0.16)]],
	"memories": [["pool", Rect2(0.16, 0.63, 0.68, 0.32)]],
	"garden": [["pool", Rect2(0.26, 0.63, 0.52, 0.32)]],
	"hieroglyphs": [["obelisk", Rect2(0.455, 0.48, 0.095, 0.37)], ["tablets", Rect2(0.0, 0.05, 0.2, 0.55)],
		["tablets", Rect2(0.8, 0.05, 0.2, 0.55)]],
	"forgotten": [["mystery_door", Rect2(0.43, 0.36, 0.15, 0.35)], ["sarcophagi", Rect2(0.01, 0.1, 0.27, 0.45)],
		["sarcophagi", Rect2(0.74, 0.1, 0.25, 0.5)]],
	"astral": [["anubis", Rect2(0.02, 0.1, 0.12, 0.55)], ["thoth", Rect2(0.22, 0.36, 0.09, 0.31)],
		["maat", Rect2(0.71, 0.32, 0.08, 0.35)], ["altar", Rect2(0.44, 0.6, 0.13, 0.17)]],
}
const ROOMS := ["hall", "archive", "memories", "garden", "hieroglyphs", "forgotten", "astral"]
const ZOOM := 1.06
const STRENGTH := 0.024

var input_enabled := true
var low_spec := false
var current_room := "hall"
var menu_mode := false

var vis := {"maat": 75.0, "ankh": 62.0, "duat": 28.0}
var target := {"maat": 75.0, "ankh": 62.0, "duat": 28.0}
var memories_lit := 0
var clues_found := 0
var forgotten_open := false
var mystery_open := false
var story_flags: Dictionary = {}

var layer: CanvasLayer
var stage: Control
var pic: TextureRect
var spots_layer: Control
var dust: CPUParticles2D
var sparks: CPUParticles2D
var _depth_img: Image
var _hover := -1
var _par := Vector2.ZERO
var _par_target := Vector2.ZERO
var _t := 0.0
var _tilt0 := Vector3.ZERO
var _tex_cache := {}


## Csak akkor váltunk festett nézetre, ha mind a hét kamrához megvan a kép és a mélységtérkép.
static func available() -> bool:
	for r in ROOMS:
		if not ResourceLoader.exists(DIR + "room_%s.png" % r) or not ResourceLoader.exists(DIR + "room_%s_depth.png" % r):
			return false
	return true


func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	stage = Control.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(stage)
	var bg := ColorRect.new()
	bg.color = T.NAVY.darkened(0.5)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(bg)
	pic = _make_pic()
	stage.add_child(pic)
	dust = _make_dust(26 if low_spec else 55, Color(1.0, 0.85, 0.55))
	stage.add_child(dust)
	sparks = _make_dust(0, Color(0.75, 0.85, 1.0))
	sparks.emitting = false
	stage.add_child(sparks)
	spots_layer = Control.new()
	spots_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spots_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spots_layer.draw.connect(_draw_spots)
	stage.add_child(spots_layer)
	stage.resized.connect(_on_resized)
	_show(current_room)


func _tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path)
	return _tex_cache[path]


func _make_pic() -> TextureRect:
	var r := TextureRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("zoom", ZOOM)
	r.material = m
	return r


func _make_dust(amount: int, col: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = maxi(amount, 1)
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.direction = Vector2(0.3, -1)
	p.spread = 60.0
	p.gravity = Vector2(0, -4)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 14.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.8
	var g := Gradient.new()
	g.set_color(0, Color(col, 0.0))
	g.set_color(1, Color(col, 0.0))
	g.add_point(0.25, Color(col, 0.55))
	g.add_point(0.75, Color(col, 0.35))
	p.color_ramp = g
	var gt := GradientTexture2D.new()
	var rg := Gradient.new()
	rg.set_color(0, Color(1, 1, 1, 1))
	rg.set_color(1, Color(1, 1, 1, 0))
	gt.gradient = rg
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 16
	gt.height = 16
	p.texture = gt
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	return p


func _show(room: String) -> void:
	var tex := _tex(DIR + "room_%s.png" % room)
	var depth := _tex(DIR + "room_%s_depth.png" % room)
	pic.texture = tex
	var m := pic.material as ShaderMaterial
	m.set_shader_parameter("depth_tex", depth)
	m.set_shader_parameter("tex_size", tex.get_size())
	m.set_shader_parameter("green_mode", 1.0 if room == "garden" else 0.0)
	_depth_img = depth.get_image()
	if _depth_img != null and _depth_img.is_compressed():
		_depth_img.decompress()
	_hover = -1
	_on_resized()
	_update_room_extras()


func _on_resized() -> void:
	var rs := stage.size
	if rs.x <= 0:
		return
	(pic.material as ShaderMaterial).set_shader_parameter("rect_size", rs)
	dust.position = rs * 0.5
	dust.emission_rect_extents = rs * 0.55
	_update_room_extras()


## Kamraspecifikus élő effektek: emlékgömbök szikrái, a kert gyógyító fényei.
func _update_room_extras() -> void:
	if sparks == null or stage == null:
		return
	var rs := stage.size
	var n := 0
	match current_room:
		"memories":
			n = 6 + memories_lit * 4
		"garden":
			n = 18 if vis.ankh >= 75.0 or story_flags.get("healing_garden", false) else 0
		"astral":
			n = 14
	n = int(n * (0.5 if low_spec else 1.0))
	sparks.emitting = n > 0
	if n > 0 and sparks.amount != n:
		sparks.amount = n
	sparks.position = Vector2(rs.x * 0.5, rs.y * 0.72)
	sparks.emission_rect_extents = Vector2(rs.x * 0.3, rs.y * 0.12)


# ------------------------------------------------------------ a 3D templom felülete
func go_to_room(room: String, instant := false) -> void:
	if not SPOTS.has(room):
		return
	if room == current_room and pic.texture != null:
		return
	_set_hover(-1)
	current_room = room
	if instant or not is_inside_tree():
		_show(room)
		return
	# átlépés: a régi kép előre zoomol és elhalványul, mögötte már az új kamra látszik
	var old := _make_pic()
	old.texture = pic.texture
	var om := old.material as ShaderMaterial
	var pm := pic.material as ShaderMaterial
	for k in ["depth_tex", "tex_size", "rect_size", "maat", "duat", "ankh", "green_mode", "tint", "glow", "offset"]:
		om.set_shader_parameter(k, pm.get_shader_parameter(k))
	stage.add_child(old)
	stage.move_child(old, pic.get_index() + 1)
	_show(room)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(v: float): om.set_shader_parameter("zoom", v), ZOOM, 1.5, 0.8)
	tw.tween_method(func(v: float): om.set_shader_parameter("alpha", v), 1.0, 0.0, 0.65)
	tw.chain().tween_callback(old.queue_free)


func is_far(_room: String) -> bool:
	return false


func set_values(values: Dictionary, animate := true) -> void:
	for k in ["maat", "ankh", "duat"]:
		if values.has(k):
			target[k] = float(values[k])
			if not animate:
				vis[k] = target[k]


func set_progress(p_memories: int, p_clues: int, p_forgotten_open: bool, p_mystery_open: bool,
		p_flags: Dictionary = {}) -> void:
	story_flags = p_flags
	memories_lit = p_memories
	clues_found = p_clues
	forgotten_open = p_forgotten_open
	mystery_open = p_mystery_open
	_update_room_extras()


func set_input_enabled(on: bool) -> void:
	input_enabled = on
	if not on:
		_set_hover(-1)


# ------------------------------------------------------------ képkocka
func _process(delta: float) -> void:
	_t += delta
	for k in vis:
		vis[k] = move_toward(vis[k], target[k], delta * 9.0)
	# lassú „lélegző” kamera + egér / döntés
	var idle := Vector2(sin(_t * 0.13) * 0.35, sin(_t * 0.09 + 1.0) * 0.22)
	var tilt := _read_tilt()
	var goal := (_par_target + tilt) * 0.85 + idle * (0.6 if menu_mode else 0.35)
	_par = _par.lerp(goal, 1.0 - exp(-delta * 2.5))
	var m := pic.material as ShaderMaterial
	m.set_shader_parameter("offset", _par * STRENGTH)
	m.set_shader_parameter("time_s", _t)
	_apply_state(m)
	dust.position = stage.size * 0.5 + _par * stage.size * STRENGTH * 0.9
	spots_layer.queue_redraw()


func _read_tilt() -> Vector2:
	if not low_spec:
		return Vector2.ZERO
	var a := Input.get_accelerometer()
	if a == Vector3.ZERO:
		return Vector2.ZERO
	if _tilt0 == Vector3.ZERO:
		_tilt0 = a
	var d := (a - _tilt0) / 9.8
	return Vector2(clampf(d.y * 2.5, -1.0, 1.0), clampf(-d.x * 2.5, -1.0, 1.0))


func _apply_state(m: ShaderMaterial) -> void:
	var maat: float = vis.maat / 100.0
	var ankh: float = vis.ankh / 100.0
	var duat: float = vis.duat / 100.0
	var tint := Vector3.ONE
	var glow := smoothstep(0.75, 0.95, maat)
	match current_room:
		"archive":
			if story_flags.get("archive_sealed", false):
				tint = Vector3(0.5, 0.48, 0.52)
			elif story_flags.get("archive_decay", false) and not story_flags.get("archive_restored", false):
				tint = Vector3(0.92, 0.8, 0.64)
		"garden":
			if story_flags.get("garden_wither", false):
				ankh = minf(ankh, 0.2)
			elif story_flags.get("healing_garden", false):
				ankh = maxf(ankh, 0.9)
		"forgotten":
			if story_flags.get("names_restored", false):
				tint = Vector3(1.1, 1.0, 0.86)
				duat *= 0.4
			else:
				duat = maxf(duat, 0.45)
		"hieroglyphs":
			glow = smoothstep(0.7, 0.9, maat) * 1.4
	m.set_shader_parameter("maat", clampf(maat, 0.0, 1.0))
	m.set_shader_parameter("ankh", clampf(ankh, 0.0, 1.0))
	m.set_shader_parameter("duat", clampf(duat, 0.0, 1.0))
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("glow", glow)
	m.set_shader_parameter("flicker", 0.6 if low_spec else 1.0)


# ------------------------------------------------------------ kattintható helyek
func _spot_rect(r: Rect2) -> Rect2:
	var a := _img_to_screen(r.position)
	var b := _img_to_screen(r.end)
	return Rect2(a, b - a)


## Képkoordináta (0..1) → képernyő, a parallax eltolással együtt.
func _img_to_screen(p: Vector2) -> Vector2:
	var rs := stage.size
	var ts: Vector2 = pic.texture.get_size() if pic.texture else Vector2(16, 9)
	var s := maxf(rs.x / ts.x, rs.y / ts.y)
	var vis_frac := rs / (ts * s)
	var d := _depth_at(p)
	var uv := p + _par * STRENGTH * (d - 0.35)
	return rs * (Vector2(0.5, 0.5) + (uv - Vector2(0.5, 0.5)) * ZOOM / vis_frac)


func _depth_at(p: Vector2) -> float:
	if _depth_img == null:
		return 0.35
	var x := clampi(int(p.x * _depth_img.get_width()), 0, _depth_img.get_width() - 1)
	var y := clampi(int(p.y * _depth_img.get_height()), 0, _depth_img.get_height() - 1)
	return _depth_img.get_pixel(x, y).r


func _spot_at(pos: Vector2) -> int:
	var list: Array = SPOTS.get(current_room, [])
	for i in list.size():
		if _spot_rect(list[i][1]).grow(6).has_point(pos):
			return i
	return -1


func _set_hover(i: int) -> void:
	if i == _hover:
		return
	_hover = i
	if i < 0:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		hover_changed.emit("", "")
	else:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		hover_changed.emit(str(SPOTS[current_room][i][0]), current_room)


func _draw_spots() -> void:
	if menu_mode or not input_enabled:
		return
	var list: Array = SPOTS.get(current_room, [])
	var pulse := 0.5 + 0.5 * sin(_t * 2.2)
	for i in list.size():
		var r := _spot_rect(list[i][1])
		var c := r.get_center()
		if i == _hover:
			# meleg fénykör a tárgy körül
			for k in 5:
				var rad := r.size * (0.42 + k * 0.08)
				_ellipse(c, rad, Color(1.0, 0.8, 0.45, 0.07))
			Fresco.diamond(spots_layer, c, 9.0, Color(T.GOLD_L, 0.95), Color(0, 0, 0, 0.6))
		else:
			spots_layer.draw_circle(c, 14.0 + pulse * 6.0, Color(1.0, 0.82, 0.45, 0.08 + pulse * 0.06))
			Fresco.diamond(spots_layer, c, 6.0, Color(T.GOLD, 0.55 + pulse * 0.35), Color(0, 0, 0, 0.5))
	if current_room == "forgotten" and mystery_open:
		var door := _spot_rect(SPOTS.forgotten[0][1])
		for k in 4:
			_ellipse(door.get_center(), door.size * (0.5 + k * 0.12 + pulse * 0.05), Color(0.7, 0.35, 1.0, 0.06))


func _ellipse(c: Vector2, rad: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 32:
		var a := TAU * k / 32.0
		pts.append(c + Vector2(cos(a) * rad.x, sin(a) * rad.y))
	spots_layer.draw_colored_polygon(pts, col)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var rs := stage.size
		if rs.x > 0:
			_par_target = (event.position / rs) * 2.0 - Vector2.ONE
		if input_enabled and not menu_mode:
			_set_hover(_spot_at(event.position))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not input_enabled or menu_mode:
			return
		var i := _spot_at(event.position)
		_set_hover(i)
		if i >= 0:
			interact.emit(str(SPOTS[current_room][i][0]), current_room)
			get_viewport().set_input_as_handled()
