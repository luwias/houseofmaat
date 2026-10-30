extends Node
## Főjelenet: a 3D templom, a HUD és az átfedő képernyők közötti navigáció.

const T = preload("res://scripts/ui/theme.gd")
const UI = preload("res://scripts/ui/ui.gd")
const Temple3D = preload("res://scripts/world/temple_3d.gd")
const HUD = preload("res://scripts/ui/hud.gd")
const Toasts = preload("res://scripts/ui/widgets/toast_stack.gd")
const MainMenu = preload("res://scripts/ui/screens/main_menu.gd")
const SoulBoard = preload("res://scripts/ui/screens/soul_board.gd")
const CaseScreen = preload("res://scripts/ui/screens/case_screen.gd")
const EvidenceInspector = preload("res://scripts/ui/screens/evidence_inspector.gd")
const CompareView = preload("res://scripts/ui/screens/compare_view.gd")
const DialoguePanel = preload("res://scripts/ui/screens/dialogue_panel.gd")
const JudgmentScreen = preload("res://scripts/ui/screens/judgment_screen.gd")
const ResultScreen = preload("res://scripts/ui/screens/result_screen.gd")
const ArchiveScreen = preload("res://scripts/ui/screens/archive_screen.gd")
const MemoryScreen = preload("res://scripts/ui/screens/memory_screen.gd")
const HieroglyphScreen = preload("res://scripts/ui/screens/hieroglyph_screen.gd")
const GardenScreen = preload("res://scripts/ui/screens/garden_screen.gd")
const ForgottenScreen = preload("res://scripts/ui/screens/forgotten_screen.gd")
const AstralScreen = preload("res://scripts/ui/screens/astral_screen.gd")
const HelpScreen = preload("res://scripts/ui/screens/help_screen.gd")
const ConfirmDialog = preload("res://scripts/ui/screens/confirm_dialog.gd")

var temple: Node3D
var layer: CanvasLayer
var root: Control
var hud: Control
var overlay_host: Control
var toasts: Control
var menu: Control
var overlays: Array = []
var fade: ColorRect


func _ready() -> void:
	add_to_group("main")
	T.build()
	temple = Temple3D.new()
	add_child(temple)
	layer = CanvasLayer.new()
	add_child(layer)
	root = Control.new()
	UI.full_rect(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = T.theme
	layer.add_child(root)
	fade = ColorRect.new()
	fade.color = Color(0.01, 0.015, 0.03, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(fade)
	root.add_child(fade)
	hud = HUD.new()
	hud.main = self
	root.add_child(hud)
	overlay_host = Control.new()
	UI.full_rect(overlay_host)
	overlay_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay_host)
	toasts = Toasts.new()
	root.add_child(toasts)

	temple.interact.connect(_on_interact)
	temple.hover_changed.connect(func(id, _room): hud.set_hover(Loc.t("hover_" + id) if id != "" else ""))
	GameState.temple_changed.connect(_on_temple_changed)
	GameState.state_changed.connect(_on_state_changed)
	GameState.toast.connect(func(text, kind): toasts.push(text, kind))
	show_menu()


# ------------------------------------------------------------ menü és játékindítás
func show_menu() -> void:
	close_all_overlays()
	hud.visible = false
	temple.menu_mode = true
	temple.go_to_room("hall", true)
	temple.set_values(GameState.temple_values(), false)
	if menu == null or not is_instance_valid(menu):
		menu = MainMenu.new()
		menu.main = self
		root.add_child(menu)
		# a menü az átfedő ablakok ALÁ kerül, hogy a megerősítés és a súgó látható legyen
		root.move_child(menu, overlay_host.get_index())


func _leave_menu() -> void:
	if menu != null and is_instance_valid(menu):
		menu.queue_free()
	menu = null
	temple.menu_mode = false
	hud.visible = true
	temple.set_values(GameState.temple_values(), false)
	_sync_temple()
	hud.refresh()


func new_game() -> void:
	GameState.new_game()
	_leave_menu()
	go_room("hall", true)
	if not GameState.data.seen_intro:
		GameState.data.seen_intro = true
		GameState.save_game()
		open_overlay(HelpScreen.new(true))


func continue_game() -> void:
	if not GameState.load_game():
		toasts.push(Loc.t("toast_load_failed"), "bad")
		return
	_leave_menu()
	var room := str(GameState.data.get("room", "hall"))
	if not GameState.room_status(room).open:
		room = "hall"
	go_room(room, true)


# ------------------------------------------------------------ navigáció
func go_room(room: String, instant := false) -> void:
	var st := GameState.room_status(room)
	if not st.open:
		toasts.push("%s – %s" % [GameData.room(room).get("name", room), st.reason], "locked")
		return
	GameState.data.room = room
	hud.set_room(room)
	if not instant and temple.is_far(room):
		# termek között rövid elsötétülés, majd áttűnés
		var tw := create_tween()
		tw.tween_property(fade, "color:a", 1.0, 0.25)
		tw.tween_callback(func(): temple.go_to_room(room, true))
		tw.tween_property(fade, "color:a", 0.0, 0.45)
	else:
		temple.go_to_room(room, instant)


func open_overlay(ov: Control) -> Control:
	ov.main = self
	overlay_host.add_child(ov)
	overlays.append(ov)
	ov.closed.connect(func(): _on_overlay_closed(ov))
	temple.set_input_enabled(false)
	hud.set_hover("")
	return ov


func _on_overlay_closed(ov: Control) -> void:
	overlays.erase(ov)
	if overlays.is_empty():
		temple.set_input_enabled(true)
		hud.refresh()
		_apply_pending_temple()


func close_all_overlays() -> void:
	for ov in overlays.duplicate():
		if is_instance_valid(ov):
			ov.queue_free()
	overlays.clear()
	temple.set_input_enabled(true)


func top_overlay() -> Control:
	return overlays.back() if not overlays.is_empty() else null


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if menu != null and is_instance_valid(menu):
			return
		var top := top_overlay()
		if top != null:
			top.close()
		else:
			confirm(Loc.t("confirm_to_menu"), show_menu)
		get_viewport().set_input_as_handled()


func _on_interact(id: String, room: String) -> void:
	if id.begins_with("door_"):
		go_room(id.substr(5))
		return
	match id:
		"scales":
			open_soul_board()
		"shelves":
			open_room_screen("archive", "evidence")
		"table":
			open_room_screen("archive", "clues")
		"pool":
			open_room_screen("memories" if room == "memories" else "garden")
		"obelisk", "tablets":
			open_room_screen("hieroglyphs")
		"sarcophagi", "mystery_door":
			open_room_screen("forgotten", id)
		"altar", "thoth", "anubis", "maat":
			open_room_screen("astral", id)


# ------------------------------------------------------------ képernyők
func open_soul_board() -> void:
	open_overlay(SoulBoard.new())


func open_case(cid: String, tab := "") -> void:
	GameState.start_case(cid)
	GameState.flush()
	for ov in overlays.duplicate():
		if ov is SoulBoard:
			ov.close()
	open_overlay(CaseScreen.new(cid, tab))


func open_evidence(cid: String, eid: String) -> void:
	open_overlay(EvidenceInspector.new(cid, eid))


func open_compare(cid: String, eid_a := "") -> void:
	open_overlay(CompareView.new(cid, eid_a))


func open_dialogue(cid: String, did: String) -> void:
	open_overlay(DialoguePanel.new(cid, did))


func open_judgment(cid: String) -> void:
	open_overlay(JudgmentScreen.new(cid))


func show_result(cid: String, result: Dictionary, replay := false) -> void:
	open_overlay(ResultScreen.new(cid, result, replay))


func return_to_hall_after_judgment() -> void:
	close_all_overlays()
	go_room("hall")
	_sync_temple()
	hud.refresh()
	_apply_pending_temple()


func open_room_screen(room: String, extra := "") -> void:
	var st := GameState.room_status(room)
	if not st.open:
		toasts.push("%s – %s" % [GameData.room(room).get("name", room), st.reason], "locked")
		return
	match room:
		"archive":
			open_overlay(ArchiveScreen.new(extra))
		"memories":
			open_overlay(MemoryScreen.new())
		"hieroglyphs":
			open_overlay(HieroglyphScreen.new())
		"garden":
			open_overlay(GardenScreen.new())
		"forgotten":
			open_overlay(ForgottenScreen.new())
		"astral":
			open_overlay(AstralScreen.new(extra))
		"hall":
			open_soul_board()


func open_help() -> void:
	open_overlay(HelpScreen.new(false))


func confirm(text: String, on_yes: Callable, yes_label := "") -> void:
	open_overlay(ConfirmDialog.new(text, on_yes, yes_label))


# ------------------------------------------------------------ állapot → világ
## Ítélet közben a templom változását visszatartjuk, hogy a játékos a Csarnokba
## visszatérve lássa, ahogy a Ház átalakul.
var _pending_temple: Dictionary = {}


func _on_temple_changed(_old: Dictionary, new_values: Dictionary) -> void:
	if overlays.is_empty():
		temple.set_values(new_values, true)
		hud.update_meters(true)
	else:
		_pending_temple = new_values


func _apply_pending_temple() -> void:
	if _pending_temple.is_empty():
		return
	temple.set_values(_pending_temple, true)
	hud.update_meters(true)
	_pending_temple = {}
	toasts.push(Loc.t("toast_temple_changes"), "info")


func _on_state_changed() -> void:
	_sync_temple()
	if hud.visible:
		hud.refresh()


func _sync_temple() -> void:
	var mem := 0
	for c in GameData.cases.values():
		for m in c.get("memories", []):
			if GameState.memory_unlocked(m.id):
				mem += 1
	temple.set_progress(mem, GameState.data.clues.size(), GameState.room_status("forgotten").open,
		GameState.has_flag("mystery_open"))
