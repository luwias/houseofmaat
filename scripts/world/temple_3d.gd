extends Node3D
## A Ma'at Háza 3D-ben. A Blenderből exportált temple.glb-t tölti be, lecseréli az anyagokat,
## fényeket, ködöt, szellemeket és gyógyító szellemeket ad hozzá, és a templom-értékek
## (Ma'at / Ankh / Duat) szerint folyamatosan, láthatóan változtatja a környezetet.

signal interact(id: String, room: String)
signal hover_changed(id: String, room: String)

const TEMPLE_PATH := "res://assets/models/temple.glb"
const GHOST_SHADER := preload("res://shaders/ghost.gdshader")
const SHADOW_SHADER := preload("res://shaders/shadow_blob.gdshader")
const HIGHLIGHT_SHADER := preload("res://shaders/highlight.gdshader")
const GLYPH_SHADER := preload("res://shaders/glyph_wall.gdshader")
const FLAME_SHADER := preload("res://shaders/flame.gdshader")
const SLAB_SHADER := preload("res://shaders/slab_stone.gdshader")

var input_enabled := true
## Gyengébb (mobil) hardver: nincs SSAO, térfogati köd és lámpaárnyék.
var low_spec := false
var current_room := "hall"
var menu_mode := false

var model: Node3D
var cam: Camera3D
var env: Environment
var sun: DirectionalLight3D

var views := {}
var room_roots := {}
var interactables := []
var cracks := []
var rubble := []
var plants := []
var waters := []
var lotus := []
var orbs := []
var clues := []
var seals := {}
var lights := []
var flames := []
var ghost_points := {}
var ghosts := []
var shadows := []
var sarc_names := []
var mats := {}
var hl_mat: ShaderMaterial
var sarc_mat: StandardMaterial3D
var spirits: Array[GPUParticles3D] = []
var spirit_rooms: Array = []

var vis := {"maat": 75.0, "ankh": 62.0, "duat": 28.0}
var target := {"maat": 75.0, "ankh": 62.0, "duat": 28.0}
var memories_lit := 0
var clues_found := 0
var forgotten_open := false
var mystery_open := false

var _hover: Dictionary = {}
var _cam_from := Vector3.ZERO
var _look := Vector3.ZERO
var _cam_tween: Tween
var _t := 0.0
var _ghost_n := -1
var _shadow_on := false
var _mouse_ndc := Vector2.ZERO
var _visible_rooms: Array = ["hall"]


func _ready() -> void:
	_build_materials()
	var scn: PackedScene = load(TEMPLE_PATH)
	model = scn.instantiate()
	add_child(model)
	_apply_materials(model)
	_collect()
	_setup_env()
	cam = Camera3D.new()
	cam.fov = 56
	cam.near = 0.1
	cam.far = 400
	add_child(cam)
	cam.make_current()
	go_to_room("hall", true)
	_apply_visuals(0.0)


# ------------------------------------------------------------ anyagok
func _noise_tex(freq: float, normal: bool, seed_v: int) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = freq
	n.fractal_octaves = 4
	var t := NoiseTexture2D.new()
	t.width = 512
	t.height = 512
	t.seamless = true
	t.noise = n
	if normal:
		t.as_normal_map = true
		t.bump_strength = 6.0
	else:
		var g := Gradient.new()
		g.set_color(0, Color(0.78, 0.78, 0.78))
		g.set_color(1, Color(1.0, 1.0, 1.0))
		t.color_ramp = g
	return t


## A vakolat-textúra világos, semleges szemcséje (a festék alá).
func _grain_tex() -> Texture2D:
	var img: Image = _tex("clay_plaster_diff").get_image()
	img.decompress()
	img.resize(256, 256)
	var lo := 1.0
	var hi := 0.0
	for y in range(0, 256, 4):
		for x in range(0, 256, 4):
			var l := img.get_pixel(x, y).get_luminance()
			lo = minf(lo, l)
			hi = maxf(hi, l)
	for y in 256:
		for x in 256:
			var l := (img.get_pixel(x, y).get_luminance() - lo) / maxf(0.001, hi - lo)
			var v := 0.82 + l * 0.18
			img.set_pixel(x, y, Color(v, v, v))
	return ImageTexture.create_from_image(img)


func _stone(color: Color, rough: float, scale: float, albedo_tex: Texture2D, normal_tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = albedo_tex
	m.normal_enabled = true
	m.normal_texture = normal_tex
	m.normal_scale = 0.6
	m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	return m


func _tex(name: String) -> Texture2D:
	return load("res://assets/textures/%s.jpg" % name)


## Valódi (CC0) PBR-textúra világtérbeli vetítéssel.
func _pbr(prefix: String, tint: Color, scale: float, rough_mul := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.albedo_texture = _tex(prefix + "_diff")
	m.normal_enabled = true
	m.normal_texture = _tex(prefix + "_nor_gl")
	m.normal_scale = 1.0
	m.roughness = rough_mul
	m.roughness_texture = _tex(prefix + "_rough")
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	return m


## Festett vakolat: lapos festékszín, alatta a vakolat valódi felszíne.
func _painted(color: Color, scale := 0.35) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = plaster_grain
	m.normal_enabled = true
	m.normal_texture = _tex("clay_plaster_nor_gl")
	m.normal_scale = 0.8
	m.roughness = 0.9
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	return m


var plaster_grain: Texture2D


func _slab(a: Color, b: Color, slab: Vector2, polish: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SLAB_SHADER
	m.set_shader_parameter("stone", a)
	m.set_shader_parameter("stone_b", b)
	m.set_shader_parameter("slab", slab)
	m.set_shader_parameter("polish", polish)
	m.set_shader_parameter("detail", _tex("clay_plaster_nor_gl"))
	m.set_shader_parameter("grain", _tex("clay_plaster_diff"))
	return m


func _build_materials() -> void:
	var nrm := _noise_tex(0.03, true, 7)
	plaster_grain = _grain_tex()
	mats["Sandstone"] = _pbr("large_sandstone_blocks_01", Color(1.0, 0.9, 0.74), 0.24)
	mats["Limestone"] = _painted(Color(0.93, 0.88, 0.76), 0.3)
	mats["Basalt"] = _slab(Color(0.11, 0.105, 0.1), Color(0.17, 0.155, 0.135), Vector2(1.6, 1.1), 0.45)
	mats["SandFloor"] = _pbr("coast_sand_01", Color(0.98, 0.9, 0.78), 0.3)
	mats["Ochre"] = _painted(Color(0.78, 0.5, 0.2))
	mats["RedOchre"] = _painted(Color(0.6, 0.22, 0.13))
	mats["Clay"] = _painted(Color(0.62, 0.38, 0.24), 0.6)
	mats["Wood"] = _pbr("dark_wood", Color(1.0, 0.85, 0.7), 0.7)
	mats["Papyrus"] = _painted(Color(0.88, 0.79, 0.57), 0.8)
	mats["Linen"] = _painted(Color(0.94, 0.91, 0.83), 0.8)
	mats["Lapis"] = _painted(Color(0.13, 0.22, 0.55))
	mats["Turquoise"] = _painted(Color(0.2, 0.6, 0.55))
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.86, 0.64, 0.24)
	gold.metallic = 1.0
	gold.roughness = 0.28
	gold.emission_enabled = true
	gold.emission = Color(0.9, 0.62, 0.2)
	gold.emission_energy_multiplier = 0.0
	mats["Gold"] = gold
	var glyph := ShaderMaterial.new()
	glyph.shader = GLYPH_SHADER
	glyph.set_shader_parameter("plaster_tex", _tex("clay_plaster_diff"))
	glyph.set_shader_parameter("plaster_nrm", _tex("clay_plaster_nor_gl"))
	mats["Glyph"] = glyph
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.06, 0.28, 0.42, 0.86)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.04
	water.metallic = 0.35
	water.normal_enabled = true
	water.normal_texture = nrm
	water.normal_scale = 0.25
	water.uv1_triplanar = true
	water.uv1_world_triplanar = true
	water.uv1_scale = Vector3(0.5, 0.5, 0.5)
	mats["Water"] = water
	var plant := StandardMaterial3D.new()
	plant.albedo_color = Color(0.25, 0.48, 0.18)
	plant.roughness = 0.8
	plant.cull_mode = BaseMaterial3D.CULL_DISABLED
	mats["Plant"] = plant
	var lotus_m := StandardMaterial3D.new()
	lotus_m.albedo_color = Color(0.95, 0.58, 0.7)
	lotus_m.emission_enabled = true
	lotus_m.emission = Color(0.6, 0.3, 0.4)
	lotus_m.emission_energy_multiplier = 0.2
	mats["Lotus"] = lotus_m
	var flame := ShaderMaterial.new()
	flame.shader = FLAME_SHADER
	mats["Flame"] = flame
	mats["Star"] = _emissive(Color(1.0, 0.9, 0.62), 3.0)
	mats["Memory"] = _emissive(Color(0.3, 0.92, 0.85), 2.5)
	mats["Void"] = _emissive(Color(0.0, 0.0, 0.0), 0.0)
	var crack := StandardMaterial3D.new()
	crack.albedo_color = Color(0.02, 0.02, 0.02)
	crack.roughness = 1.0
	mats["Crack"] = crack
	var night := StandardMaterial3D.new()
	night.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	night.albedo_color = Color(0.015, 0.025, 0.07)
	mats["Night"] = night
	hl_mat = ShaderMaterial.new()
	hl_mat.shader = HIGHLIGHT_SHADER
	sarc_mat = _emissive(Color(0.62, 0.35, 0.95), 0.0)


func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.emission_enabled = energy > 0.0
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _apply_materials(root: Node) -> void:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var sm := mi.mesh.surface_get_material(i)
			if sm == null:
				continue
			var key := sm.resource_name
			if key.contains("."):
				key = key.get_slice(".", 0)
			if mats.has(key):
				mi.set_surface_override_material(i, mats[key])


# ------------------------------------------------------------ jelenet-feltérképezés
func _room_of(n: Node) -> String:
	var p := n
	while p != null and p != model:
		var nm := String(p.name)
		if nm.begins_with("Room_"):
			return nm.substr(5)
		p = p.get_parent()
	return ""


func _world_aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	var list := n.find_children("*", "MeshInstance3D", true, false)
	if n is MeshInstance3D:
		list.append(n)
	for m in list:
		var mi := m as MeshInstance3D
		var a: AABB = mi.global_transform * mi.get_aabb()
		out = a if first else out.merge(a)
		first = false
	return out


func _collect() -> void:
	var interact_re := RegEx.new()
	interact_re.compile("^Interact_([a-z_]+?)(?:[._]?\\d+)?$")
	var all := model.find_children("*", "", true, false)
	for n in all:
		var nm := String(n.name)
		if nm.begins_with("Room_"):
			room_roots[nm.substr(5)] = n
	for n in all:
		var nm := String(n.name)
		var room := _room_of(n)
		if nm.begins_with("Cam_"):
			var r := nm.substr(4)
			if not views.has(r):
				views[r] = {}
			views[r]["pos"] = (n as Node3D).global_position
		elif nm.begins_with("Look_"):
			var r := nm.substr(5)
			if not views.has(r):
				views[r] = {}
			views[r]["look"] = (n as Node3D).global_position
		elif nm.begins_with("Interact_"):
			var m := interact_re.search(nm)
			var id := m.get_string(1) if m else nm.substr(9)
			_make_interactable(n, id, room)
		elif nm.begins_with("Crack_") and n is MeshInstance3D:
			cracks.append({"node": n, "th": 15.0 + float(absi(hash(nm)) % 46), "room": room})
		elif nm.begins_with("Rubble_") and n is MeshInstance3D:
			rubble.append({"node": n, "th": 10.0 + float(absi(hash(nm)) % 36)})
		elif nm.begins_with("Plant_") and n is MeshInstance3D:
			plants.append({"node": n})
		elif nm.begins_with("Water_") and n is MeshInstance3D:
			waters.append({"node": n, "y": (n as Node3D).position.y, "channel": nm.contains("channel")})
		elif nm.begins_with("Lotus_") and n is MeshInstance3D:
			lotus.append(n)
		elif nm.begins_with("Orb_") and n is MeshInstance3D:
			var om := (mats["Memory"] as StandardMaterial3D).duplicate()
			(n as MeshInstance3D).material_override = om
			orbs.append({"node": n, "mat": om, "base": (n as Node3D).position, "idx": int(nm.substr(4))})
		elif nm.begins_with("Clue_") and n is MeshInstance3D:
			clues.append({"node": n, "idx": int(nm.substr(5))})
		elif nm.begins_with("Seal_") and n is MeshInstance3D:
			seals[nm.substr(5)] = n
		elif nm.begins_with("Light_"):
			_make_light(n as Node3D, room)
		elif nm.begins_with("Flame_") and n is MeshInstance3D:
			flames.append({"node": n, "scale": (n as Node3D).scale, "phase": randf() * TAU})
		elif nm.begins_with("Ghost_"):
			if not ghost_points.has(room):
				ghost_points[room] = []
			ghost_points[room].append((n as Node3D).global_position)
		elif nm.begins_with("Sarc_") and nm.ends_with("_name") and n is MeshInstance3D:
			sarc_names.append(n)
	orbs.sort_custom(func(x, y): return x.idx < y.idx)
	clues.sort_custom(func(x, y): return x.idx < y.idx)
	for p in plants:
		_pivot_plant(p)
	_make_spirits()


func _make_interactable(n: Node, id: String, room: String) -> void:
	var aabb := _world_aabb(n)
	if aabb.size == Vector3.ZERO:
		return
	var area := Area3D.new()
	area.collision_layer = 1
	area.collision_mask = 0
	area.monitoring = false
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size + Vector3(0.3, 0.3, 0.3)
	cs.shape = box
	area.add_child(cs)
	add_child(area)
	area.global_position = aabb.get_center()
	var meshes := n.find_children("*", "MeshInstance3D", true, false)
	var item := {"id": id, "room": room, "area": area, "meshes": meshes}
	area.set_meta("item", interactables.size())
	interactables.append(item)


func _make_light(marker: Node3D, room: String) -> void:
	var l := OmniLight3D.new()
	var kind := "flame"
	match room:
		"memories", "astral":
			kind = "cool"
		"forgotten":
			kind = "dim"
	var nm := String(marker.name)
	if nm.contains("_w"):
		kind = "wall"
	match kind:
		"flame":
			l.light_color = Color(1.0, 0.66, 0.36)
			l.light_energy = 2.6
			l.omni_range = 13.0
		"wall":
			l.light_color = Color(1.0, 0.75, 0.5)
			l.light_energy = 1.4
			l.omni_range = 16.0
		"cool":
			l.light_color = Color(0.45, 0.9, 0.95)
			l.light_energy = 2.2
			l.omni_range = 15.0
		"dim":
			l.light_color = Color(0.5, 0.55, 0.9)
			l.light_energy = 1.3
			l.omni_range = 14.0
	l.omni_attenuation = 1.2
	l.shadow_enabled = kind == "flame" and room == "hall" and not low_spec
	add_child(l)
	l.global_position = marker.global_position
	lights.append({"light": l, "base": l.light_energy, "phase": randf() * TAU, "kind": kind, "room": room})


func _pivot_plant(p: Dictionary) -> void:
	var n: MeshInstance3D = p.node
	var aabb := _world_aabb(n)
	var pivot := Node3D.new()
	var parent := n.get_parent()
	parent.add_child(pivot)
	pivot.global_position = Vector3(aabb.get_center().x, aabb.position.y, aabb.get_center().z)
	var gt := n.global_transform
	parent.remove_child(n)
	pivot.add_child(n)
	n.global_transform = gt
	p["pivot"] = pivot


func _make_spirits() -> void:
	for spot in [{"room": "garden", "size": Vector3(9, 1.5, 6)}, {"room": "hall", "size": Vector3(4, 1.5, 4)}]:
		var r: String = spot.room
		if not views.has(r):
			continue
		var p := GPUParticles3D.new()
		p.amount = 48
		p.lifetime = 5.0
		p.preprocess = 3.0
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = spot.size
		pm.gravity = Vector3(0, 0.12, 0)
		pm.initial_velocity_min = 0.05
		pm.initial_velocity_max = 0.25
		pm.direction = Vector3(0, 1, 0)
		pm.spread = 60.0
		pm.scale_min = 0.6
		pm.scale_max = 1.4
		pm.color = Color(0.7, 1.0, 0.6)
		p.process_material = pm
		var q := QuadMesh.new()
		q.size = Vector2(0.12, 0.12)
		var qm := StandardMaterial3D.new()
		qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		qm.albedo_color = Color(0.75, 1.0, 0.55, 0.9)
		qm.vertex_color_use_as_albedo = true
		q.material = qm
		p.draw_pass_1 = q
		add_child(p)
		var look: Vector3 = views[r].get("look", Vector3.ZERO)
		p.global_position = look + Vector3(0, 0.6, 0) if r == "garden" else Vector3(look.x, 2.2, look.z - 1.0)
		p.emitting = false
		spirits.append(p)
		spirit_rooms.append(r)


# ------------------------------------------------------------ környezet
func _setup_env() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.03, 0.05, 0.13)
	psm.sky_horizon_color = Color(0.42, 0.26, 0.16)
	psm.ground_bottom_color = Color(0.02, 0.02, 0.03)
	psm.ground_horizon_color = Color(0.3, 0.2, 0.13)
	psm.sun_angle_max = 25.0
	sky.sky_material = psm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.47, 0.36)
	env.ambient_light_energy = 0.42
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.1
	env.ssao_enabled = not low_spec
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.volumetric_fog_enabled = not low_spec
	# mobilon egyszerű mélységi köd a térfogati helyett
	env.fog_enabled = low_spec
	env.fog_light_color = Color(0.35, 0.27, 0.2)
	env.fog_density = 0.008
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color(0.9, 0.8, 0.7)
	env.volumetric_fog_anisotropy = 0.3
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.05
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32, 35, 0)
	sun.light_color = Color(1.0, 0.68, 0.45)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	if low_spec:
		sun.directional_shadow_max_distance = 40
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 120
	add_child(sun)


# ------------------------------------------------------------ kamera
func go_to_room(room: String, instant := false) -> void:
	if not views.has(room):
		return
	var prev := current_room
	current_room = room
	_clear_hover()
	var v: Dictionary = views[room]
	var pos: Vector3 = v.get("pos", Vector3.ZERO)
	var look: Vector3 = v.get("look", Vector3.ZERO)
	if _cam_tween:
		_cam_tween.kill()
	if instant or cam == null:
		_cam_from = pos
		_look = look
		_show_rooms([room])
		return
	_show_rooms([prev, room])
	var far := _cam_from.distance_to(pos) > 30.0
	if far:
		# termek között „áttűnés”: gyors repülés felülről
		_cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_cam_tween.tween_property(self, "_cam_from", pos, 1.4)
		_cam_tween.tween_property(self, "_look", look, 1.4)
	else:
		_cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_cam_tween.tween_property(self, "_cam_from", pos, 0.9)
		_cam_tween.tween_property(self, "_look", look, 0.9)
	_cam_tween.chain().tween_callback(func(): _show_rooms([current_room]))


func is_far(room: String) -> bool:
	if not views.has(room):
		return false
	return _cam_from.distance_to(views[room].get("pos", Vector3.ZERO)) > 30.0


## Csak a látható termek (és fényeik) maradnak bekapcsolva: a nyitott kertből így nem
## látszanak a többi terem külső falai, és a renderelés is gyorsabb.
func _show_rooms(list: Array) -> void:
	for r in room_roots:
		(room_roots[r] as Node3D).visible = r in list
	for L in lights:
		(L.light as Node3D).visible = L.room in list
	for i in spirits.size():
		spirits[i].visible = spirit_rooms[i] in list
	for g in ghosts:
		(g.node as Node3D).visible = g.room in list
	for sh in shadows:
		(sh.node as Node3D).visible = sh.room in list
	_visible_rooms = list


func _update_camera(delta: float) -> void:
	if cam == null:
		return
	var sway := Vector3(sin(_t * 0.23) * 0.25, sin(_t * 0.31) * 0.12, 0)
	var par := Vector3(_mouse_ndc.x * 0.35, -_mouse_ndc.y * 0.18, 0)
	var pos := _cam_from
	var look := _look
	if menu_mode:
		var ang := _t * 0.06
		pos = _look + Vector3(sin(ang) * 6.0, 0.0, 0.0) + (_cam_from - _look)
		sway *= 0.5
	cam.global_position = pos + sway + par
	cam.look_at(look + par * 0.4, Vector3.UP)
	var _unused := delta


# ------------------------------------------------------------ templom-állapot
func set_values(values: Dictionary, animate := true) -> void:
	for k in ["maat", "ankh", "duat"]:
		if values.has(k):
			target[k] = float(values[k])
			if not animate:
				vis[k] = target[k]


var story_flags: Dictionary = {}


func set_progress(p_memories: int, p_clues: int, p_forgotten_open: bool, p_mystery_open: bool,
		p_flags: Dictionary = {}) -> void:
	story_flags = p_flags
	memories_lit = p_memories
	clues_found = p_clues
	forgotten_open = p_forgotten_open
	mystery_open = p_mystery_open


func _process(delta: float) -> void:
	_t += delta
	for k in vis:
		vis[k] = move_toward(vis[k], target[k], delta * 9.0)
	_apply_visuals(delta)
	_update_camera(delta)


func _apply_visuals(delta: float) -> void:
	var maat: float = vis.maat
	var ankh: float = vis.ankh
	var duat: float = vis.duat
	var km := smoothstep(15.0, 85.0, maat)
	var ka := smoothstep(15.0, 85.0, ankh)
	var kd := smoothstep(30.0, 90.0, duat)

	# arany: magas Ma'at-nál fényes és izzó, alacsonynál fakó bronz
	var gold: StandardMaterial3D = mats["Gold"]
	gold.albedo_color = Color(0.42, 0.32, 0.2).lerp(Color(0.88, 0.66, 0.26), km)
	gold.metallic = lerpf(0.35, 1.0, km)
	gold.roughness = lerpf(0.75, 0.24, km)
	gold.emission_energy_multiplier = maxf(0.0, (maat - 70.0) / 30.0) * 0.55
	# hieroglifák
	var glyph: ShaderMaterial = mats["Glyph"]
	glyph.set_shader_parameter("glow", smoothstep(62.0, 100.0, maat) * 0.6 * (0.8 + 0.2 * sin(_t * 1.3)))
	glyph.set_shader_parameter("decay", 1.0 - smoothstep(20.0, 60.0, maat))
	# repedések és törmelék
	var decay: bool = story_flags.has("archive_decay") and not story_flags.has("archive_restored")
	for c in cracks:
		(c.node as Node3D).visible = maat < c.th or (decay and c.room == "archive")
	for r in rubble:
		(r.node as Node3D).visible = maat < r.th
	# növények
	var plant: StandardMaterial3D = mats["Plant"]
	# a történet nyomai a kertben: Nefru gyógyító kertje vagy az elhervadt kamilla
	var healing: bool = story_flags.has("healing_garden")
	var wither: bool = story_flags.has("garden_wither") and not healing
	if healing:
		ka = minf(1.0, ka + 0.25)
	elif wither:
		ka = maxf(0.0, ka - 0.25)
	plant.albedo_color = Color(0.45, 0.33, 0.15).lerp(Color(0.22, 0.5, 0.17), ka)
	var sy := lerpf(0.45, 1.06, ka)
	for p in plants:
		if p.has("pivot"):
			var pv: Node3D = p.pivot
			pv.scale = Vector3(lerpf(0.8, 1.0, ka), sy + sin(_t * 0.8 + pv.position.x) * 0.015, lerpf(0.8, 1.0, ka))
	# víz
	var water: StandardMaterial3D = mats["Water"]
	water.uv1_offset = Vector3(_t * 0.01, 0, _t * 0.006)
	water.albedo_color = Color(0.3, 0.24, 0.14, 0.65).lerp(Color(0.12, 0.42, 0.58, 0.92), ka)
	for w in waters:
		var wn: Node3D = w.node
		var drop := (1.0 - ka) * (0.25 if not w.channel else 0.06)
		wn.position.y = w.y - drop
		wn.visible = ankh >= 18.0 or not w.channel
	for l in lotus:
		(l as Node3D).visible = ankh >= 45.0 or healing
	for i in spirits.size():
		spirits[i].emitting = ankh >= 70.0 or (healing and spirit_rooms[i] == "garden")
	# fények
	var lf := lerpf(0.5, 1.15, km)
	var flick := lerpf(0.22, 0.06, km)
	for L in lights:
		var light: OmniLight3D = L.light
		var f := 1.0
		if L.kind == "flame":
			f = 1.0 + flick * sin(_t * 9.0 + L.phase) + flick * 0.6 * sin(_t * 23.0 + L.phase * 2.0)
		light.light_energy = L.base * lf * f
		if L.room == "forgotten":
			light.light_color = Color(0.5, 0.55, 0.9).lerp(Color(0.62, 0.35, 0.95), smoothstep(45.0, 70.0, duat))
	for fl in flames:
		var fn: Node3D = fl.node
		var s: Vector3 = fl.scale
		fn.scale = Vector3(s.x * 0.8, s.y * (1.0 + 0.15 * sin(_t * 11.0 + fl.phase)), s.z * 0.8) * lerpf(0.7, 1.0, km)
	# köd: a Duat sötétebb, lilább, sűrűbb ködöt hoz
	env.volumetric_fog_density = 0.008 + kd * 0.03
	if low_spec:
		env.fog_density = 0.004 + kd * 0.02
		env.fog_light_color = Color(0.35, 0.27, 0.2).lerp(Color(0.25, 0.18, 0.4), kd)
	env.volumetric_fog_albedo = Color(0.9, 0.8, 0.7).lerp(Color(0.45, 0.35, 0.75), kd)
	env.ambient_light_energy = lerpf(0.25, 0.48, km)
	env.adjustment_saturation = lerpf(0.75, 1.08, km)
	# Elfeledett Szárny
	var forgotten_active := duat >= 50.0
	var restored: bool = story_flags.has("names_restored")
	if restored:
		sarc_mat.albedo_color = Color(1.0, 0.8, 0.35)
		sarc_mat.emission = Color(1.0, 0.75, 0.3)
	sarc_mat.emission_energy_multiplier = 2.5 if (forgotten_active or restored) else 0.0
	for sn in sarc_names:
		(sn as MeshInstance3D).material_override = sarc_mat if (forgotten_active or restored) else null
	if seals.has("forgotten"):
		(seals["forgotten"] as Node3D).visible = not forgotten_open
	if seals.has("mystery"):
		(seals["mystery"] as Node3D).visible = not mystery_open
	# emlékgömbök és nyomok
	for i in orbs.size():
		var o: Dictionary = orbs[i]
		var lit := i < memories_lit
		var om: StandardMaterial3D = o.mat
		om.emission_energy_multiplier = (2.6 + 0.6 * sin(_t * 2.0 + i)) if lit else 0.15
		om.albedo_color = Color(0.3, 0.92, 0.85) if lit else Color(0.18, 0.25, 0.3)
		(o.node as Node3D).position = o.base + Vector3(0, sin(_t * 1.1 + i) * (0.12 if lit else 0.02), 0)
	for i in clues.size():
		(clues[i].node as Node3D).visible = i < clues_found
	_update_ghosts(duat, delta)


func _update_ghosts(duat: float, _delta: float) -> void:
	var n := 0
	if duat >= 40.0:
		n = clampi(int((duat - 40.0) / 7.0) + 1, 1, 6)
	if n != _ghost_n:
		_ghost_n = n
		for g in ghosts:
			g.node.queue_free()
		ghosts.clear()
		for room in ghost_points:
			var pts: Array = ghost_points[room]
			for i in mini(n, pts.size()):
				var mi := MeshInstance3D.new()
				var q := QuadMesh.new()
				q.size = Vector2(1.1, 2.1)
				mi.mesh = q
				var sm := ShaderMaterial.new()
				sm.shader = GHOST_SHADER
				sm.set_shader_parameter("phase", randf() * 10.0)
				sm.set_shader_parameter("intensity", 0.55)
				mi.material_override = sm
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(mi)
				var a: Vector3 = pts[i]
				var b: Vector3 = pts[(i + 1) % pts.size()]
				mi.visible = room in _visible_rooms
				ghosts.append({"node": mi, "a": a, "b": b, "speed": randf_range(0.05, 0.12), "off": randf() * TAU, "mat": sm,
					"room": room})
	for g in ghosts:
		var k := 0.5 + 0.5 * sin(_t * g.speed * TAU + g.off)
		var pos: Vector3 = (g.a as Vector3).lerp(g.b, k)
		pos.y += sin(_t * 1.3 + g.off) * 0.25
		(g.node as Node3D).global_position = pos
		(g.mat as ShaderMaterial).set_shader_parameter("intensity", clampf((duat - 35.0) / 40.0, 0.2, 0.9))
	# mozgó árnyak a folyosókon
	var want_shadows := duat >= 55.0
	if want_shadows != _shadow_on:
		_shadow_on = want_shadows
		for s in shadows:
			s.node.queue_free()
		shadows.clear()
		if want_shadows:
			for room in ["hall", "archive", "forgotten"]:
				if not views.has(room):
					continue
				var look: Vector3 = views[room].look
				for i in 3:
					var mi := MeshInstance3D.new()
					var pm := PlaneMesh.new()
					pm.size = Vector2(3.2, 1.6)
					mi.mesh = pm
					var sm := ShaderMaterial.new()
					sm.shader = SHADOW_SHADER
					sm.set_shader_parameter("phase", randf() * 10.0)
					mi.material_override = sm
					add_child(mi)
					mi.visible = room in _visible_rooms
					shadows.append({"node": mi, "c": Vector3(look.x, 0.04, look.z - 6.0), "off": randf() * TAU,
						"r": randf_range(3, 7), "room": room})
	for s in shadows:
		var p: Vector3 = s.c + Vector3(sin(_t * 0.25 + s.off) * s.r, 0, cos(_t * 0.18 + s.off) * s.r * 0.7)
		(s.node as Node3D).global_position = p
		(s.node as Node3D).rotation.y = _t * 0.1 + s.off


# ------------------------------------------------------------ interakció
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var vp := get_viewport().get_visible_rect().size
		_mouse_ndc = (event.position / vp) * 2.0 - Vector2.ONE
		if input_enabled and not menu_mode:
			_pick(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# érintőképernyőn nincs előzetes egérmozgás: koppintáskor itt választunk
		if input_enabled and not menu_mode:
			_pick(event.position)
		if input_enabled and not menu_mode and not _hover.is_empty():
			interact.emit(_hover.id, _hover.room)
			get_viewport().set_input_as_handled()


func _pick(screen_pos: Vector2) -> void:
	var from := cam.project_ray_origin(screen_pos)
	var to := from + cam.project_ray_normal(screen_pos) * 80.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var item: Dictionary = {}
	if not hit.is_empty() and hit.collider.has_meta("item"):
		var cand: Dictionary = interactables[int(hit.collider.get_meta("item"))]
		if cand.room == current_room:
			item = cand
	if item.get("area") == _hover.get("area"):
		return
	_clear_hover()
	if not item.is_empty():
		_hover = item
		for m in item.meshes:
			(m as GeometryInstance3D).material_overlay = hl_mat
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		hover_changed.emit(item.id, item.room)


func _clear_hover() -> void:
	if _hover.is_empty():
		return
	for m in _hover.meshes:
		if is_instance_valid(m):
			(m as GeometryInstance3D).material_overlay = null
	_hover = {}
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	hover_changed.emit("", "")


func set_input_enabled(on: bool) -> void:
	input_enabled = on
	if not on:
		_clear_hover()
