extends SubViewportContainer
## 3D tárgynézegető: egérrel forgatható, görgővel nagyítható.

signal rotated_back

var _vp: SubViewport
var _pivot: Node3D
var _cam: Camera3D
var _drag := false
var _yaw := 0.4
var _pitch := 0.5
var _dist := 4.2
var _back_reported := false


func setup(model_path: String) -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	add_child(_vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.45, 0.4)
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	_vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, 30, 0)
	key.light_energy = 1.6
	key.light_color = Color(1.0, 0.85, 0.65)
	_vp.add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-2, 1.5, -2)
	rim.light_color = Color(0.4, 0.7, 1.0)
	rim.light_energy = 2.0
	rim.omni_range = 8
	_vp.add_child(rim)
	_pivot = Node3D.new()
	_vp.add_child(_pivot)
	if ResourceLoader.exists(model_path):
		var scn: PackedScene = load(model_path)
		var inst := scn.instantiate()
		_pivot.add_child(inst)
		_fit(inst)
	_cam = Camera3D.new()
	_cam.fov = 40
	_vp.add_child(_cam)
	_update_cam()


func _fit(inst: Node) -> void:
	var aabb := AABB()
	var first := true
	for m in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var a: AABB = mi.global_transform * mi.get_aabb() if mi.is_inside_tree() else mi.transform * mi.get_aabb()
		aabb = a if first else aabb.merge(a)
		first = false
	if not first:
		(inst as Node3D).position = -aabb.get_center()
		_dist = maxf(aabb.size.length() * 1.25, 1.5)


func _update_cam() -> void:
	if _cam == null:
		return
	var dir := Vector3(cos(_pitch) * sin(_yaw), sin(_pitch), cos(_pitch) * cos(_yaw))
	_cam.position = dir * _dist
	_cam.look_at(Vector3.ZERO, Vector3.UP)
	# a tábla hátoldala akkor látszik, ha alulról / hátulról nézzük
	if not _back_reported and _pitch < -0.35:
		_back_reported = true
		rotated_back.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_drag = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_dist = maxf(1.0, _dist * 0.9)
			_update_cam()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_dist = minf(12.0, _dist * 1.1)
			_update_cam()
	elif event is InputEventMouseMotion and _drag:
		_yaw -= event.relative.x * 0.01
		_pitch = clampf(_pitch + event.relative.y * 0.01, -1.45, 1.45)
		_update_cam()


func _process(delta: float) -> void:
	if not _drag and _pivot != null:
		_yaw += delta * 0.15
		_update_cam()


func show_back() -> void:
	_pitch = -0.9
	_update_cam()
