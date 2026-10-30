extends Node
## Logikai tesztek fej nélküli futtatáshoz:
##   godot --headless --path . res://tests/test_runner.tscn
## Ellenőrzi: adatintegritás, mind a négy befejezés, minden kizáró döntés-kombináció
## (zsákutca-mentesség), félrevezető bizonyítékok kezelése, mentés/betöltés.

const Cond = preload("res://scripts/systems/conditions.gd")
const Dlg = preload("res://scripts/systems/dialogue.gd")
const Validator = preload("res://scripts/systems/story_validator.gd")
const Judgment = preload("res://scripts/systems/judgment.gd")

var GS
var case_data: Dictionary
var fails := 0
var passes := 0


func _ready() -> void:
	GS = GameState
	GS.autosave = false
	GS.save_path = "user://test_save.json"
	case_data = GameData.get_case("kha")
	test_data_integrity()
	test_loc_keys()
	test_best_route()
	test_naive_route()
	test_unresolved_route()
	test_all_branch_combinations()
	test_misleading_evidence()
	test_save_load()
	test_temple_effects()
	print("\n==== %d sikeres, %d hibás ====" % [passes, fails])
	get_tree().quit(1 if fails > 0 else 0)


func ok(cond: bool, msg: String) -> void:
	if cond:
		passes += 1
		print("  OK   ", msg)
	else:
		fails += 1
		print("  FAIL ", msg)


func fresh() -> void:
	GS.reset_state()
	GS.start_case("kha")
	GS.flush()


# ------------------------------------------------------------ segédek
func talk(did: String, path: Array) -> void:
	## A megadott szövegrészletek szerint választ opciót, csomópontról csomópontra.
	var nid := "start"
	Dlg.enter(case_data, did, nid, GS)
	for want in path:
		var picked := -1
		for o in Dlg.options(case_data, did, nid, GS):
			if str(o.opt.text).contains(want):
				picked = int(o.index)
				break
		if picked < 0:
			ok(false, "nincs ilyen opció: %s / %s / „%s”" % [did, nid, want])
			return
		var nx := Dlg.choose(case_data, did, nid, picked, GS)
		if nx == "end":
			return
		Dlg.enter(case_data, did, nx, GS)
		nid = nx
	GS.flush()


func inspect_all() -> void:
	for ev in case_data.evidence:
		if GS.has_evidence(ev.id) and not GS.is_corrupted(ev.id):
			GS.mark_inspected(ev.id)
			for a in ev.get("inspect", []):
				GS.reveal(ev.id, str(a.id))
	GS.flush()


func compare_all() -> void:
	var ids := []
	for ev in case_data.evidence:
		if GS.has_evidence(ev.id):
			ids.append(ev.id)
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			GS.compare_evidence("kha", ids[i], ids[j])
	GS.flush()


func translate_all() -> void:
	for tr in case_data.get("translations", []):
		if not GS.has_evidence(str(tr.evidence)):
			continue
		var all_known := true
		for g in tr.glyphs:
			if not GS.knows_glyph(str(g.answer)):
				all_known = false
		if all_known:
			Cond.apply(tr.effects, GS, "kha")
	GS.flush()


func clarify_all() -> void:
	for m in case_data.get("memories", []):
		if not GS.memory_unlocked(m.id):
			continue
		var frags: Array = m.fragments
		for i in frags.size():
			if frags[i].get("blurred", false) and GS.has_evidence(str(frags[i].get("clarify_with", ""))):
				GS.clarify(m.id, i, "kha")
	GS.flush()


func explore_dialogue(did: String, forced: Dictionary) -> void:
	for _iter in 40:
		var nid := "start"
		Dlg.enter(case_data, did, nid, GS)
		var moved := false
		for _depth in 12:
			var opts := Dlg.options(case_data, did, nid, GS)
			var pick = null
			for o in opts:
				if o.opt.has("group") and str(forced.get(str(o.opt.group), "")) == str(o.opt.get("value", "")):
					pick = o
					break
			if pick == null:
				for o in opts:
					var nx := str(o.opt.get("next", "end"))
					if o.opt.has("group") or nx == "end":
						continue
					if nx == "hostile" and not forced.get("hostile", false):
						continue
					if nid != "start" or not GS.node_visited("%s.%s" % [did, nx]) or o.opt.get("once", false):
						pick = o
						break
			if pick == null:
				break
			var nxt := Dlg.choose(case_data, did, nid, int(pick.index), GS)
			if nxt == "end":
				break
			Dlg.enter(case_data, did, nxt, GS)
			nid = nxt
			moved = true
			if nid == "start":
				break
		GS.flush()
		if not moved:
			break


func explore_everything(forced: Dictionary) -> void:
	var last := -1
	for _round in 12:
		if forced.get("hostile", false) and not GS.has_flag("merit_hostile") and not GS.has_flag("merit_revealed"):
			talk("merit", ["Te segítettél"])
		for br in case_data.investigation + case_data.encounters:
			if Cond.check(br.get("unlock", true), GS):
				explore_dialogue(str(br.dialogue), forced)
		inspect_all()
		compare_all()
		translate_all()
		clarify_all()
		var n: int = GS.data.evidence.size() + GS.data.flags.size()
		if n == last:
			break
		last = n


func best_board() -> void:
	GS.set_board_slot("kha", "childhood", ["c_kha", "e_poverty", "K01", "m_father_ship"])
	GS.set_board_slot("kha", "wealth", ["c_kha", "e_embezzlement", "c_djehuty", "K10"])
	GS.set_board_slot("kha", "marriage", ["c_kha", "c_merit", "e_staged_death", "K10"])
	GS.set_board_slot("kha", "betrayal", ["c_djehuty", "c_hapu", "e_secret_agreement", "K07"])
	GS.set_board_slot("kha", "death", ["c_kha", "c_hapu", "e_murder", "K14", "K12"])
	GS.flush()


func states() -> Dictionary:
	var out := {}
	var r := Validator.evaluate_board(case_data, GS)
	for k in r:
		out[k] = r[k].state
	return out


# ------------------------------------------------------------ tesztek
func test_data_integrity() -> void:
	print("\n[adatintegritás]")
	var cards: Dictionary = case_data._cards
	var bad := []
	for sc in case_data.scenes:
		for it in sc.interpretations:
			for key in ["required", "optional", "support", "contradict"]:
				for id in it.get(key, []):
					if not cards.has(id):
						bad.append("%s.%s: %s" % [it.id, key, id])
	for ev in case_data.evidence:
		for id in ev.get("associated", []):
			if not cards.has(id):
				bad.append("%s.associated: %s" % [ev.id, id])
	ok(bad.is_empty(), "minden hivatkozott kártya létezik %s" % [bad])
	var bad_next := []
	var bad_ev := []
	for did in case_data.dialogues:
		var nodes: Dictionary = case_data.dialogues[did].nodes
		for nid in nodes:
			for o in nodes[nid].get("options", []):
				var nx := str(o.get("next", "end"))
				if nx != "end" and not nodes.has(nx):
					bad_next.append("%s.%s → %s" % [did, nid, nx])
				for e in o.get("effects", []):
					if e.has("unlock_evidence"):
						for id in Cond._arr(e.unlock_evidence):
							if not case_data._evidence.has(id):
								bad_ev.append(id)
	ok(bad_next.is_empty(), "minden párbeszéd-átmenet létező csomópontra mutat %s" % [bad_next])
	ok(bad_ev.is_empty(), "minden feloldott bizonyíték létezik %s" % [bad_ev])
	for tr in case_data.translations:
		for g in tr.glyphs:
			ok(GameData.lexicon.has(str(g.answer)), "a fordítás jele ismert a szótárban: %s" % g.answer)
	ok(case_data.evidence.size() == 14, "Kha esetében 14 bizonyíték van")
	ok(case_data.scenes.size() == 5, "Kha esetében 5 jelenet van")
	ok(case_data.endings.size() >= 3, "legalább 3 befejezés")


func test_loc_keys() -> void:
	print("\n[nyelvi kulcsok]")
	var re := RegEx.new()
	re.compile("Loc\\.t\\(\"([a-z_]+)\"[,)]")
	var missing := []
	for path in _all_scripts("res://scripts"):
		var src := FileAccess.get_file_as_string(path)
		for m in re.search_all(src):
			var k := m.get_string(1)
			if not Loc.has_key(k) and not k.ends_with("_"):
				missing.append(k)
	for p in ["state_confirmed", "state_supported", "state_uncertain", "state_contradicted", "state_fabricated",
			"state_incomplete", "state_empty", "cat_all_pl", "cat_evidence_pl", "deity_thoth_desc", "hover_scales",
			"hover_door_archive", "insp_found_rotate", "type_record", "arch_tab_clues", "stat_duat", "tab_storyboard"]:
		if not Loc.has_key(p):
			missing.append(p)
	ok(missing.is_empty(), "minden felületi szövegkulcs megvan %s" % [missing])


func _all_scripts(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		out += _all_scripts(dir.path_join(sub))
	return out


func test_best_route() -> void:
	print("\n[A útvonal – a teljes összeesküvés]")
	fresh()
	GS.reveal("K01", "flip")
	GS.reveal("K02", "magnify")
	ok(GS.has_evidence("K08"), "a nagyító feltárja a kettős pecsétet (K08)")
	GS.reveal("K04", "glyphs")
	talk("ipy", ["Kha kereskedőéről", "Folytatod"])
	ok(GS.has_evidence("K06"), "Ipy naplója (K06)")
	GS.compare_evidence("kha", "K04", "K06")
	ok(GS.has_flag("delay_found"), "a K04 és K06 összevetése felfedi a három napos eltérést")
	talk("ipy", ["Valaki megfizetett", "A Ma'at mérlege", "Folytatod"])
	ok(GS.has_evidence("K09"), "Ipy átadja a titkos szerződést (K09)")
	talk("ipy", ["Ki hozta be", "Folytatod"])
	ok(GS.has_evidence("K14"), "testazonosítás (K14)")
	talk("harbor", ["Mely hajók", "Folytatod"])
	ok(GS.has_evidence("K12") and GS.card_available("c_hapu"), "hajójegyzék és Hapu kártyája")
	talk("harbor", ["Hol találom Hapu", "Folytatod"])
	talk("treasury", ["Kérem a Kha", "Folytatod"])
	talk("treasury", ["Kettős pecsét", "Folytatod"])
	ok(GS.has_evidence("K11") and GS.card_available("c_djehuty"), "második aláírás és Djehuty azonosítása")
	talk("merit", ["Mesélj róla", "Folytatod"])
	ok(GS.has_evidence("K03") and GS.memory_unlocked("M2"), "Merit átadja a titkos levelet, emlék nyílik")
	talk("merit", ["Titkos szerződés", "Folytatod"])
	ok(GS.has_evidence("K10") and GS.has_flag("merit_revealed"), "a szerződés hatására Merit felfedi a tervet")
	talk("merit", ["Felszállt", "Folytatod"])
	talk("merit", ["részt vett", "Folytatod"])
	talk("hapu", ["Hajójegyzék", "Mérlegeled"])
	talk("hapu", ["Titkos szerződés", "Folytatod"])
	ok(GS.has_evidence("K13") and GS.get_reliability("K13") >= 80, "a szerződéssel szerzett vallomás megbízható")
	ok(GS.has_evidence("K07"), "rejtett kifizetés (K07)")
	ok(GS.get_choice("hapu_approach") == "contract", "a kizáró döntés rögzítve")
	inspect_all()
	translate_all()
	ok(GS.has_flag("k03_translated"), "a titkos levél lefordítható a megtanult jelekkel")
	clarify_all()
	ok(GS.has_clue("CL_golden_hand"), "az arany kéz nyoma az Archívumba kerül")
	best_board()
	var st := states()
	for k in st:
		ok(st[k] in ["confirmed", "supported"], "jelenet „%s”: %s" % [k, st[k]])
	var comp := Judgment.compute(case_data, GS)
	ok(comp.complete, "a rekonstrukció teljes")
	ok(comp.params.truth >= 85, "magas igazság (%d)" % comp.params.truth)
	ok(comp.params.evidence >= 70, "magas bizonyítékérték (%d)" % comp.params.evidence)
	var a := Judgment.resolve(case_data, "mercy", GS)
	ok(a.ending == "A" and a.category == "just_mercy", "felmentés → A, igazságos kegyelem (%s/%s)" % [a.ending, a.category])
	var a2 := Judgment.resolve(case_data, "penance", GS)
	ok(a2.ending == "A" and a2.category == "just_accountability", "vezeklés → A, igazságos számonkérés")
	var b := Judgment.resolve(case_data, "condemn", GS)
	ok(b.ending == "B" and b.category == "unjust_condemnation", "elítélés a teljes igazság ismeretében → B")
	var c := Judgment.resolve(case_data, "unresolved", GS)
	ok(c.ending == "C", "felfüggesztés → C")
	ok(not a.explain.is_empty(), "az ítélethez magyarázat tartozik")
	# a bűnrészesség elhallgatása nem vezethet igazságos felmentéshez
	GS.set_board_slot("kha", "wealth", ["c_kha", "e_treasury_deal", "o_gold"])
	GS.flush()
	var d := Judgment.resolve(case_data, "mercy", GS)
	ok(d.ending == "D" and d.category == "unjust_forgiveness", "a bűnrészesség elhallgatásával a felmentés igazságtalan (szándék ≠ tett)")


func test_naive_route() -> void:
	print("\n[B útvonal – a hamis tekercseknek hinni]")
	fresh()
	GS.set_board_slot("kha", "childhood", ["c_kha", "e_poverty"])
	GS.set_board_slot("kha", "wealth", ["c_kha", "e_embezzlement", "K02"])
	GS.set_board_slot("kha", "marriage", ["c_kha", "c_merit", "e_wedding"])
	GS.set_board_slot("kha", "betrayal", ["c_kha", "o_royal_seal", "o_gold", "K02"])
	GS.set_board_slot("kha", "death", ["c_kha", "e_natural_death", "K04"])
	GS.flush()
	var st := states()
	ok(st.wealth == "supported", "a félrevezető tekercs alátámasztja a „tolvaj” értelmezést (%s)" % st.wealth)
	ok(st.wealth != "confirmed", "félrevezető értelmezés sosem lehet megerősített")
	ok(st.marriage in ["fabricated", "uncertain"], "bizonyíték nélküli jelenet nem erősödik meg (%s)" % st.marriage)
	var comp := Judgment.compute(case_data, GS)
	ok(comp.params.truth < 50, "alacsony igazságtartalom (%d)" % comp.params.truth)
	var b := Judgment.resolve(case_data, "condemn", GS)
	ok(b.ending == "B" and b.category == "unjust_condemnation", "elítélés → B, igazságtalan elítélés")
	var d := Judgment.resolve(case_data, "mercy", GS)
	ok(d.ending == "D" and d.category == "unjust_forgiveness", "megalapozatlan felmentés → D (a kegyesség nem jutalom)")


func test_unresolved_route() -> void:
	print("\n[C útvonal – a szökés ismert, a gyilkosság nem bizonyított]")
	fresh()
	talk("ipy", ["Kha kereskedőéről", "Folytatod"])
	GS.compare_evidence("kha", "K04", "K06")
	talk("ipy", ["Valaki megfizetett", "Ha hallgatsz", "Folytatod"])
	ok(GS.has_evidence("K09") and GS.get_reliability("K09") < 85, "fenyegetéssel is megszerezhető a szerződés, de kevésbé megbízható")
	talk("merit", ["Titkos szerződés", "Folytatod"])
	talk("harbor", ["Mely hajók", "Folytatod"])
	GS.set_board_slot("kha", "childhood", ["c_kha", "e_poverty"])
	GS.set_board_slot("kha", "wealth", ["c_kha", "e_embezzlement", "c_djehuty"])
	GS.set_board_slot("kha", "marriage", ["c_kha", "c_merit", "e_staged_death"])
	GS.set_board_slot("kha", "betrayal", ["c_kha", "c_djehuty", "e_exposure"])
	GS.set_board_slot("kha", "death", ["c_kha", "e_staged_death", "e_escape"])
	GS.flush()
	ok(not GS.card_available("e_murder"), "a „Gyilkosság” kártya nem jelenik meg bizonyíték nélkül")
	var c := Judgment.resolve(case_data, "unresolved", GS)
	ok(c.ending == "C" and c.category == "unresolved", "felfüggesztés → C, a befejezetlen utazás")
	var d := Judgment.resolve(case_data, "mercy", GS)
	ok(d.ending == "D", "bizonyítatlan gyilkosság mellett a felmentés elhamarkodott → D")


func test_all_branch_combinations() -> void:
	print("\n[minden kizáró döntés-kombináció – zsákutca-ellenőrzés]")
	for hapu in ["threat", "contract", "protect"]:
		for ipy in ["maat", "threat"]:
			for hostile in [false, true]:
				fresh()
				explore_everything({"hapu_approach": hapu, "ipy_approach": ipy, "hostile": hostile})
				var missing := []
				for ev in case_data.evidence:
					if ev.get("required", false) and not GS.has_evidence(ev.id):
						missing.append(ev.id)
				best_board()
				var res := Judgment.resolve(case_data, "mercy", GS)
				var label := "Hapu=%s, Ipy=%s, Merit ellenséges=%s" % [hapu, ipy, hostile]
				ok(missing.is_empty(), "%s: minden kötelező bizonyíték elérhető %s" % [label, missing])
				ok(res.get("ending", "") == "A", "%s: az A befejezés elérhető (%s, igazság %d)" % [label,
					res.get("ending", "?"), int(res.get("params", {}).get("truth", 0))])


func test_misleading_evidence() -> void:
	print("\n[félrevezető bizonyítékok és ellentmondások]")
	fresh()
	GS.set_board_slot("kha", "betrayal", ["c_kha", "o_royal_seal", "o_gold"])
	GS.flush()
	ok(states().betrayal == "supported", "„Kha elárulja a kincstárat” kezdetben alátámasztottnak tűnik")
	GS.reveal("K02", "magnify")
	GS.flush()
	ok(states().betrayal == "contradicted", "a kettős pecsét feltárása után ellentmondásos")
	GS.compare_evidence("kha", "K02", "K08")
	ok(GS.get_reliability("K02") <= 30, "az összevetés lerontja a hamis tekercs megbízhatóságát")
	ok(GS.board("kha").betrayal.size() == 3, "a játékos rekonstrukciója megmarad")
	# nem létező bizonyítékot nem lehet felhasználni
	fresh()
	GS.set_board_slot("kha", "death", ["c_kha", "e_natural_death", "K14"])
	GS.flush()
	var r: Dictionary = Validator.evaluate_board(case_data, GS).death
	ok(not "K14" in r.contradict, "fel nem tárt bizonyíték nem számít bele a validációba")


func test_save_load() -> void:
	print("\n[mentés és betöltés]")
	fresh()
	talk("harbor", ["Mely hajók", "Folytatod"])
	GS.set_board_slot("kha", "childhood", ["c_kha", "e_poverty"])
	GS.set_temple({"maat": 60})
	GS.save_game()
	GS.reset_state()
	ok(not GS.has_evidence("K12"), "a törlés után nincs K12")
	ok(GS.load_game(), "a mentés betölthető")
	ok(GS.has_evidence("K12"), "a feltárt bizonyíték megmaradt")
	ok(GS.node_visited("harbor.manifest"), "a párbeszéd-előzmény megmaradt")
	ok(GS.board("kha").childhood == ["c_kha", "e_poverty"], "a rekonstrukció megmaradt")
	ok(is_equal_approx(GS.get_stat("maat"), 60.0), "a templom-értékek megmaradtak")
	GS.delete_save()


func test_temple_effects() -> void:
	print("\n[templom-hatások]")
	GS.reset_state()
	ok(GS.get_stat("maat") == 75 and GS.get_stat("ankh") == 62 and GS.get_stat("duat") == 28, "kezdőértékek 75/62/28")
	GS.apply_outcome("unjust_condemnation")
	ok(GS.get_stat("maat") == 60 and GS.get_stat("duat") == 43, "igazságtalan elítélés: Ma'at −15, Duat +15")
	GS.set_temple({"maat": 98, "duat": 2})
	GS.apply_outcome("just_mercy")
	ok(GS.get_stat("maat") == 100 and GS.get_stat("duat") == 0, "az értékek 0 és 100 között maradnak")
	GS.reset_state()
	ok(GS.room_status("astral").open, "Asztrális Kamra nyitva 75 Ma'at-nál")
	GS.set_temple({"maat": 45})
	ok(not GS.room_status("astral").open, "Asztrális Kamra bezárul 50 Ma'at alatt")
	ok(not GS.room_status("forgotten").open, "Elfeledett Szárny kezdetben zárva")
	GS.set_temple({"duat": 55})
	ok(GS.room_status("forgotten").open, "magas Duat mellett az Elfeledett Szárny felébred")
