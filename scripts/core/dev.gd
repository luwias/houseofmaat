extends Node
## Fejlesztői segéd: parancssorból képernyőképeket készít előre megírt forgatókönyvek szerint.
##   godot --path . -- --shot=<mappa> --scenario=tour
## Normál indításkor semmit sem csinál.

var args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if args.has("shot"):
		GameState.save_path = "user://dev_save.json"
		call_deferred("_run")


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := str(args.shot)
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir.path_join(name + ".png"))
	print("SHOT ", name)


func _run() -> void:
	await _wait(1.0)
	var main := get_tree().get_first_node_in_group("main")
	var scen := str(args.get("scenario", "tour"))
	match scen:
		"tour":
			await _tour(main)
		"case":
			await _case(main)
		"states":
			await _states(main)
	get_tree().quit()


func _tour(main) -> void:
	await _wait(2.0)
	await shot("01_menu")
	GameState.data.seen_intro = true
	main.new_game()
	GameState.data.seen_intro = true
	main.close_all_overlays()
	await _wait(2.5)
	await shot("02_hall")
	for r in ["archive", "memories", "garden", "hieroglyphs", "forgotten", "astral"]:
		main.temple.go_to_room(r, true)
		main.hud.set_room(r)
		await _wait(1.5)
		await shot("03_room_" + r)
	main.go_room("hall", true)
	await _wait(1.0)
	main.open_soul_board()
	await _wait(0.8)
	await shot("04_souls")


func _case(main) -> void:
	main.new_game()
	main.close_all_overlays()
	main.open_case("kha")
	await _wait(1.0)
	await shot("10_briefing")
	var cs = main.top_overlay()
	cs._on_tab("investigation")
	await _wait(0.6)
	await shot("11_investigation")
	main.open_dialogue("kha", "merit")
	await _wait(3.5)
	await shot("12_dialogue")
	main.top_overlay().close()
	cs._on_tab("evidence")
	await _wait(0.6)
	await shot("13_evidence")
	main.open_evidence("kha", "K01")
	await _wait(0.8)
	await shot("14_inspect_portrait")
	main.top_overlay().close()
	GameState.unlock_evidence("K08")
	main.open_evidence("kha", "K08")
	await _wait(1.5)
	await shot("15_inspect_seal3d")
	main.top_overlay().close()
	# néhány kártya a papiruszra
	GameState.set_board_slot("kha", "childhood", ["c_kha", "e_poverty", "K01"])
	GameState.set_board_slot("kha", "wealth", ["c_kha", "e_embezzlement"])
	GameState.set_board_slot("kha", "marriage", ["c_merit", "e_wedding", "c_kha"])
	GameState.set_board_slot("kha", "betrayal", ["c_kha", "o_royal_seal", "o_gold"])
	GameState.set_board_slot("kha", "death", ["c_kha"])
	GameState.flush()
	cs._on_tab("storyboard")
	await _wait(0.8)
	await shot("16_storyboard")
	GameState.set_board_slot("kha", "death", ["c_kha", "e_natural_death"])
	GameState.flush()
	main.open_judgment("kha")
	await _wait(1.0)
	await shot("17_judgment")


func _states(main) -> void:
	main.new_game()
	main.close_all_overlays()
	main.temple.menu_mode = false
	for preset in [["high", 95, 92, 8], ["low", 18, 15, 85]]:
		GameState.set_temple({"maat": preset[1], "ankh": preset[2], "duat": preset[3]})
		main.temple.set_values(GameState.temple_values(), false)
		main.hud.update_meters(false)
		for r in ["hall", "garden"]:
			main.temple.go_to_room(r, true)
			main.hud.set_room(r)
			await _wait(1.5)
			await shot("20_%s_%s" % [preset[0], r])
