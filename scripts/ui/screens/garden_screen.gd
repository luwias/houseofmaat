extends "res://scripts/ui/widgets/overlay.gd"
## A Nádmező Kertje: az Ankh állapota, a gyógyító forrás (megrontott bizonyítékok
## megtisztítása) és a helyreállító áldozat magas Ankh esetén.

var box: VBoxContainer


func build() -> void:
	var p := centered(Vector2(980, 680), UI.papyrus(32))
	box = UI.vbox(14)
	p.add_child(UI.scroll(box))
	refresh()


func refresh() -> void:
	UI.clear(box)
	var r := GameData.room("garden")
	var h := UI.hbox(12)
	h.add_child(UI.glyphs("𓇋", 36, T.RED_INK))
	h.add_child(UI.title(r.name, 30, T.RED_INK))
	h.add_child(UI.spacer())
	h.add_child(UI.ink_button(Loc.t("btn_close") + "  ✕", close))
	box.add_child(h)
	box.add_child(UI.ink(r.purpose, 16))
	var ankh := GameState.get_stat("ankh")
	box.add_child(UI.title(Loc.t("garden_ankh", [int(ankh)]), 20, T.INK))
	box.add_child(UI.ink(GameState.room_state_text("garden"), 17))
	box.add_child(UI.separator(T.INK_L))
	# gyógyító forrás
	box.add_child(UI.title(Loc.t("garden_spring"), 20, T.RED_INK))
	var th := float(GameData.temple.get("purify_ankh", 40))
	var corrupted: Array = GameState.data.corrupted.keys()
	if corrupted.is_empty():
		box.add_child(UI.ink(Loc.t("garden_no_corruption"), 16))
	else:
		for eid in corrupted:
			var row := UI.hbox(10)
			row.add_child(UI.ink("%s – %s" % [eid, GameData.evidence(eid).get("title", eid)], 16))
			var b := UI.ink_button(Loc.t("garden_purify"), _purify.bind(eid))
			b.disabled = ankh < th
			row.add_child(b)
			box.add_child(row)
		if ankh < th:
			box.add_child(UI.label(Loc.t("garden_purify_low", [int(th)]), 14, T.RED_INK, true))
	box.add_child(UI.separator(T.INK_L))
	# helyreállító áldozat
	box.add_child(UI.title(Loc.t("garden_restore"), 20, T.RED_INK))
	var rth := float(GameData.temple.get("restore_ankh", 70))
	var judged := 0
	for cid in GameData.cases:
		if GameState.case_done(cid):
			judged += 1
	var used: int = GameState.data.restored.size()
	box.add_child(UI.ink(Loc.t("garden_restore_desc", [int(rth)]), 16))
	var rb := UI.ink_button(Loc.t("garden_restore_btn"), _restore)
	rb.disabled = ankh < rth or used >= judged
	box.add_child(rb)
	if used >= judged:
		box.add_child(UI.label(Loc.t("garden_restore_wait"), 14, T.INK_L, true))
	elif ankh < rth:
		box.add_child(UI.label(Loc.t("garden_restore_low"), 14, T.INK_L, true))


func _purify(eid: String) -> void:
	GameState.purify(eid)
	GameState.flush()


func _restore() -> void:
	GameState.data.restored[str(GameState.data.restored.size())] = true
	var v := GameState.temple_values()
	GameState.set_temple({"maat": v.maat + 4, "duat": v.duat - 4})
	GameState.toast.emit(Loc.t("toast_restored"), "good")
	GameState.flush()
	refresh()
