extends "res://scripts/ui/widgets/overlay.gd"
## Az Elfeledett Szárny: az elítélt és lezáratlan lelkek, és a Ház lepecsételt titka.

var box: VBoxContainer


func build() -> void:
	var p := centered(Vector2(1100, 720))
	box = UI.vbox(14)
	p.add_child(UI.scroll(box))
	refresh()


func refresh() -> void:
	UI.clear(box)
	var r := GameData.room("forgotten")
	box.add_child(header(r.name, "𓃀", r.purpose))
	box.add_child(UI.label(GameState.room_state_text("forgotten"), 16, T.SAND, true))
	box.add_child(UI.separator())
	box.add_child(UI.title(Loc.t("fw_souls"), 20, T.GOLD))
	var any := false
	for hrec in GameState.data.history:
		if str(hrec.destination) in ["forgotten_wing", "chamber_of_memories", "archive_unresolved"]:
			any = true
			var soul := GameData.soul(str(hrec.case))
			var cat := GameData.category(str(hrec.category))
			var p := UI.box_panel(Color(T.DEEP, 0.7), Color(str(cat.get("color", "8a8fa8"))), 1, 14)
			var hh := UI.hbox(12)
			p.add_child(hh)
			hh.add_child(UI.glyphs(str(soul.get("glyph", "")), 30, T.DUAT))
			var tv := UI.vbox(2)
			tv.add_child(UI.title("%s – %s" % [soul.get("name", ""), hrec.title], 19, T.PAPYRUS))
			tv.add_child(UI.label("%s · %s" % [cat.get("label", ""), GameData.destination_label(str(hrec.destination))], 14, T.SAND))
			if str(hrec.category) == "unresolved":
				tv.add_child(UI.label(Loc.t("fw_reopen_later"), 13, T.MUTED, true))
			hh.add_child(tv)
			box.add_child(p)
	if not any:
		box.add_child(UI.label(Loc.t("fw_empty"), 15, T.MUTED, true))
	box.add_child(UI.separator())
	box.add_child(UI.title(Loc.t("fw_door"), 20, T.GOLD))
	var found := 0
	var total := 0
	for c in GameData.mystery.get("clues", []):
		total += 1
		if GameState.has_clue(c.id):
			found += 1
	box.add_child(UI.label(str(GameData.mystery.get("door_text", "")), 16, T.GOLD_L, true))
	box.add_child(UI.label(Loc.t("fw_clues", [found, total]), 15, T.SAND))
	box.add_child(UI.label(Loc.t("fw_door_locked"), 14, T.MUTED, true))
