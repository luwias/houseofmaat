extends Node
## Logikai tesztek fej nélküli futtatáshoz:
##   godot --headless --path . res://tests/test_runner.tscn
## Ellenőrzi: adatintegritás, mind a négy befejezés, minden kizáró döntés-kombináció
## (zsákutca-mentesség), félrevezető bizonyítékok kezelése, mentés/betöltés.

const Cond = preload("res://scripts/systems/conditions.gd")
const Dlg = preload("res://scripts/systems/dialogue.gd")
const Validator = preload("res://scripts/systems/story_validator.gd")
const Judgment = preload("res://scripts/systems/judgment.gd")
const House = preload("res://scripts/systems/house_judgment.gd")

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
	test_card_copies()
	test_dialogue_replay()
	for cid in ["kha", "nefru", "hori"]:
		test_case_generic(cid)
	test_final_mystery()
	case_data = GameData.get_case("kha")
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


func fresh(cid := "") -> void:
	if cid != "":
		case_data = GameData.get_case(cid)
	GS.reset_state()
	GS.start_case(case_data.id)
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
			GS.compare_evidence(case_data.id, ids[i], ids[j])
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
			Cond.apply(tr.effects, GS, case_data.id)
	GS.flush()


func clarify_all() -> void:
	for m in case_data.get("memories", []):
		if not GS.memory_unlocked(m.id):
			continue
		var frags: Array = m.fragments
		for i in frags.size():
			if frags[i].get("blurred", false) and GS.has_evidence(str(frags[i].get("clarify_with", ""))):
				GS.clarify(m.id, i, case_data.id)
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
		if forced.get("hostile", false) and case_data.id == "kha" and not GS.has_flag("merit_hostile") and not GS.has_flag("merit_revealed"):
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
	GS.set_board_slot("kha", "marriage", ["c_kha", "c_merit", "e_staged_death", "K03"])
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
	for v in case_data.ideal.verdicts:
		var iv := Judgment.resolve(case_data, str(v), GS)
		ok(str(iv.category).begins_with("just_"), "a „helyes ítéletként” megadott %s valóban igazságos" % v)
	for v in GameData.temple.verdicts:
		ok(str(v.get("consequence", "")) != "", "a(z) %s ítéletnek van leírt következménye" % v.id)
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
	GS.set_board_slot("kha", "betrayal", ["c_kha", "o_royal_seal", "o_gold", "K05"])
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
	GS.set_note("kha", "Ipy hazudik a dátumról?")
	GS.save_game()
	GS.reset_state()
	ok(GS.get_note("kha") == "", "új játékban üres a jegyzetfüzet")
	GS.load_game()
	ok(GS.get_note("kha") == "Ipy hazudik a dátumról?", "a saját jegyzetek megmaradnak mentés után")
	GS.delete_save()


func board_within_copies() -> bool:
	var count := {}
	for sid in GS.board("kha"):
		for id in GS.board("kha")[sid]:
			count[id] = int(count.get(id, 0)) + 1
	for id in count:
		if count[id] > int(GameData.card(id).get("copies", 1)):
			print("    túl sok példány: ", id, " ", count[id])
			return false
	return true


func test_card_copies() -> void:
	print("
[kártyapéldányok]")
	ok(GameData.card("c_kha").copies == 5, "Kha kártyája 5 példányban (mind az 5 jelenethez kell)")
	ok(GameData.card("c_djehuty").copies >= 2, "Djehuty több jelenetben is kell (%d)" % GameData.card("c_djehuty").copies)
	ok(GameData.card("K10").copies == 1, "egy bizonyíték 1 példányban")
	ok(GameData.card("e_poverty").copies == 1, "a „Nélkülözés” 1 példányban")
	fresh()
	ok(GS.card_remaining("kha", "e_poverty") == 1, "elhelyezés előtt 1 maradt")
	GS.set_board_slot("kha", "childhood", ["c_kha", "e_poverty"])
	ok(GS.card_remaining("kha", "e_poverty") == 0, "elhelyezés után elfogy a tálcáról")
	ok(GS.card_remaining("kha", "c_kha") == 4, "Kha kártyájából 4 maradt")
	GS.set_board_slot("kha", "childhood", ["c_kha"])
	ok(GS.card_remaining("kha", "e_poverty") == 1, "visszavéve újra elérhető")
	# a legjobb kirakás és minden tesztkirakás belefér a példányszámokba
	fresh()
	explore_everything({"hapu_approach": "contract", "ipy_approach": "maat", "hostile": false})
	best_board()
	ok(board_within_copies(), "a teljes igazság kirakható a rendelkezésre álló példányokból")
	ok(Judgment.resolve(case_data, "mercy", GS).ending == "A", "és A befejezéshez vezet")


func test_dialogue_replay() -> void:
	print("
[újrakérdezés]")
	fresh()
	ok(Dlg.heard(case_data, "ipy", GS).is_empty(), "meghallgatás előtt nincs mit újrakérdezni")
	talk("ipy", ["Kha kereskedőéről", "Folytatod"])
	talk("ipy", ["Ki hozta be", "Folytatod"])
	var h := Dlg.heard(case_data, "ipy", GS)
	ok(h.size() == 2, "két meghallgatott válasz (%d)" % h.size())
	ok(h[0].node == "ledger" and str(h[0].question).contains("Kha kereskedőéről"), "a kérdés és a válasz-csomópont párban")
	ok(not Dlg.options(case_data, "ipy", "start", GS).any(func(o): return str(o.opt.text).contains("Kha kereskedőéről")),
		"az egyszeri kérdés a rendes beszélgetésből eltűnt – ezért kell az újrakérdezés")
	var before := JSON.stringify(GS.data)
	Dlg.heard(case_data, "ipy", GS)
	Dlg.node(case_data, "ipy", "ledger")
	ok(JSON.stringify(GS.data) == before, "az újrakérdezés semmit nem változtat az állapoton")


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


# ------------------------------------------------------------ általános, minden esetre
func groups_of(cd: Dictionary) -> Dictionary:
	var g := {}
	for did in cd.dialogues:
		for nid in cd.dialogues[did].nodes:
			for o in cd.dialogues[did].nodes[nid].get("options", []):
				if o.has("group"):
					if not g.has(o.group):
						g[o.group] = []
					if not str(o.value) in g[o.group]:
						g[o.group].append(str(o.value))
	return g


func combos(groups: Dictionary) -> Array:
	var out := [{}]
	for k in groups:
		var nxt := []
		for base in out:
			for v in groups[k]:
				var c: Dictionary = base.duplicate()
				c[k] = v
				nxt.append(c)
		out = nxt
	return out


## A legjobb (legnagyobb igazságú) értelmezés kirakása a feltárt elemekből, a példányszámokat betartva.
func best_board_auto() -> void:
	var used := {}
	for sc in case_data.scenes:
		var best: Dictionary = {}
		for it in sc.interpretations:
			if best.is_empty() or float(it.truth) > float(best.truth):
				best = it
		var cards := []
		for id in best.required + best.get("support", []):
			if cards.size() >= Validator.MAX_CARDS or id in cards or not GS.card_available(id):
				continue
			if int(used.get(id, 0)) >= int(GameData.card(id).get("copies", 1)):
				continue
			cards.append(id)
			used[id] = int(used.get(id, 0)) + 1
		GS.set_board_slot(case_data.id, sc.id, cards)
	GS.flush()


func test_case_generic(cid: String) -> void:
	print("\n[%s – általános ellenőrzés]" % cid)
	case_data = GameData.get_case(cid)
	var cards: Dictionary = case_data._cards
	var bad := []
	for sc in case_data.scenes:
		for it in sc.interpretations:
			for key in ["required", "optional", "support", "contradict"]:
				for id in it.get(key, []):
					if not cards.has(id):
						bad.append("%s.%s:%s" % [it.id, key, id])
	for ev in case_data.evidence:
		for id in ev.get("associated", []):
			if not cards.has(id):
				bad.append("%s:%s" % [ev.id, id])
		for c in ev.get("contradictions", []):
			if not case_data._evidence.has(str(c.with)):
				bad.append("%s ellentmondás:%s" % [ev.id, c.with])
	for did in case_data.dialogues:
		var nodes: Dictionary = case_data.dialogues[did].nodes
		for nid in nodes:
			for o in nodes[nid].get("options", []):
				var nx := str(o.get("next", "end"))
				if nx != "end" and not nodes.has(nx):
					bad.append("%s.%s→%s" % [did, nid, nx])
	for br in case_data.investigation + case_data.encounters:
		if not case_data.dialogues.has(br.dialogue):
			bad.append("ág:%s" % br.dialogue)
	for c in case_data.comparisons:
		for e in c.pair:
			if not case_data._evidence.has(str(e)):
				bad.append("összevetés:%s" % e)
	for tr in case_data.get("translations", []):
		for g in tr.glyphs:
			if not GameData.lexicon.has(str(g.answer)):
				bad.append("jel:%s" % g.answer)
	for v in case_data.ideal.verdicts:
		if GameData.verdict(str(v)).is_empty():
			bad.append("ítélet:%s" % v)
	ok(bad.is_empty(), "%s: minden hivatkozás érvényes %s" % [cid, bad])
	ok(case_data.evidence.size() >= 10, "%s: legalább 10 bizonyíték (%d)" % [cid, case_data.evidence.size()])
	ok(case_data.scenes.size() == 5, "%s: 5 jelenet" % cid)
	ok(case_data.investigation.size() == 4, "%s: 4 nyomozási ág" % cid)
	ok(case_data.endings.size() >= 3, "%s: legalább 3 befejezés" % cid)

	for forced in combos(groups_of(case_data)):
		var f: Dictionary = forced.duplicate()
		fresh(cid)
		explore_everything(f)
		var missing := []
		for ev in case_data.evidence:
			if ev.get("required", false) and not GS.has_evidence(ev.id):
				missing.append(ev.id)
		best_board_auto()
		var label := "%s %s" % [cid, forced]
		ok(missing.is_empty(), "%s: minden kötelező bizonyíték elérhető %s" % [label, missing])
		ok(board_within_copies(), "%s: a kirakás belefér a kártyapéldányokba" % label)
		for v in case_data.ideal.verdicts:
			var r := Judgment.resolve(case_data, str(v), GS)
			ok(r.get("ending", "") == "A" and str(r.category).begins_with("just_"),
				"%s: %s → A (%s, igazság %d)" % [label, v, r.get("ending", "?"), int(r.get("params", {}).get("truth", 0))])
	var rb := Judgment.resolve(case_data, "condemn", GS)
	ok(rb.ending == "B" and rb.category == "unjust_condemnation", "%s: elítélés → B" % cid)
	var rc := Judgment.resolve(case_data, "unresolved", GS)
	ok(rc.ending == "C", "%s: felfüggesztés → C" % cid)
	# bizonyíték nélküli felmentés soha nem igazságos
	fresh(cid)
	for sc in case_data.scenes:
		var worst: Dictionary = {}
		for it in sc.interpretations:
			if worst.is_empty() or float(it.truth) < float(worst.truth):
				worst = it
		var cards2 := []
		for id in worst.required:
			if GS.card_available(id):
				cards2.append(id)
		GS.set_board_slot(cid, sc.id, cards2)
	GS.flush()
	var rd := Judgment.resolve(case_data, "mercy", GS)
	ok(not str(rd.category).begins_with("just_"), "%s: megalapozatlan felmentés nem igazságos (%s)" % [cid, rd.ending])


func play_case_best(cid: String) -> void:
	case_data = GameData.get_case(cid)
	GS.start_case(cid)
	GS.flush()
	var forced := {}
	var groups := groups_of(case_data)
	for k in groups:
		forced[k] = groups[k][0]
	if cid == "kha":
		forced["hapu_approach"] = "contract"
	explore_everything(forced)
	best_board_auto()
	var r := Judgment.resolve(case_data, str(case_data.ideal.verdicts[0]), GS)
	GS.record_judgment(cid, r)
	GS.flush()


func test_final_mystery() -> void:
	print("\n[a Ház titka – végső ítélet]")
	GS.reset_state()
	ok(not House.is_open(GS), "a belső kapu kezdetben zárva")
	ok(not Cond.check(GameData.soul("nefru").unlock, GS), "Nefru csak Kha után érkezik")
	play_case_best("kha")
	ok(Cond.check(GameData.soul("nefru").unlock, GS), "Kha ítélete után Nefru megérkezik")
	play_case_best("nefru")
	ok(GS.has_flag("healing_garden"), "Nefru A befejezése gyógyító kertet hoz")
	play_case_best("hori")
	ok(GS.has_flag("archive_restored"), "Hori A befejezése helyreállítja az Archívumot")
	ok(House.is_open(GS), "mindhárom ítélet után megnyílik a belső kapu")
	for a in House.final_data().actions:
		Cond.apply(a.effects, GS)
	GS.flush()
	ok(GS.data.clues.size() >= 8, "elegendő nyom gyűlt össze (%d)" % GS.data.clues.size())
	var saved: Dictionary = GS.data.duplicate(true)
	var cases := {
		"F1": {"q1": "amenemope", "q2": "neferhotep", "q3": "expose"},
		"F3": {"q1": "djehuty", "q2": "neferhotep", "q3": "expose"},
		"F4": {"q1": "amenemope", "q2": "neferhotep", "q3": "silence"},
		"F5": {"q1": "amenemope", "q2": "victim", "q3": "close"}
	}
	for want in cases:
		GS.data = saved.duplicate(true)
		var r := House.resolve(cases[want], GS)
		ok(r.get("ending", "") == want, "válaszok %s → %s (%s)" % [cases[want], want, r.get("ending", "?")])
	GS.data = saved.duplicate(true)
	var r1 := House.resolve(cases.F1, GS)
	var before: float = GS.get_stat("maat")
	House.apply(r1, GS)
	ok(GS.has_flag("names_restored") and GS.get_stat("maat") >= before and GS.get_stat("duat") < 20, "a megtisztított Ház visszaírja a neveket")
	ok(str(r1.epilogue) == str(House.final_data().epilogue_just), "igazságos ítéletek után igazságos epilógus")
	GS.data = saved.duplicate(true)
	var few := {}
	for k in GS.data.clues.keys().slice(0, 4):
		few[k] = true
	GS.data.clues = few
	var r2 := House.resolve(cases.F1, GS)
	ok(r2.get("ending", "") == "F2", "helyes válasz kevés nyommal → bizonyítatlan vád (F2)")
