extends "res://scripts/ui/widgets/overlay.gd"
## Az Asztrális Kamra: tanács Thottól (írás, igazság), Anubisztól (halál, test)
## és Ma'attól (a mérleg jelenlegi állása).

const Cond = preload("res://scripts/systems/conditions.gd")
const Dlg = preload("res://scripts/systems/dialogue.gd")
const Judgment = preload("res://scripts/systems/judgment.gd")

const DEITIES := ["thoth", "anubis", "maat"]
const GLYPHS := {"thoth": "𓅝", "anubis": "𓃣", "maat": "𓆄"}

var focus := ""
var answers := {}
var box: VBoxContainer


func _init(p_focus := "") -> void:
	focus = p_focus


func build() -> void:
	var p := centered(Vector2(1260, 760))
	box = UI.vbox(14)
	p.add_child(box)
	refresh()
	if focus in DEITIES:
		_consult(focus)


func _case_id() -> String:
	var cid := str(GameState.data.active_case)
	if cid != "" and not GameState.case_done(cid):
		return cid
	for c in GameData.cases:
		if GameState.case_state(c).get("status", "") == "in_progress":
			return c
	return ""


func refresh() -> void:
	UI.clear(box)
	var r := GameData.room("astral")
	box.add_child(header(r.name, "𓇼", r.purpose))
	box.add_child(UI.separator())
	var cid := _case_id()
	if cid == "":
		box.add_child(UI.label(Loc.t("astral_no_case"), 17, T.SAND, true))
		return
	box.add_child(UI.label(Loc.t("astral_case", [GameData.soul(cid).name]), 16, T.SAND))
	var h := UI.hbox(16)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(h)
	for d in DEITIES:
		var p := UI.papyrus(20)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(10)
		p.add_child(v)
		v.add_child(UI.glyphs(GLYPHS[d], 56, T.RED_INK))
		v.add_child(UI.title(Loc.t("deity_" + d), 22, T.RED_INK, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UI.label(Loc.t("deity_" + d + "_desc"), 14, T.INK_L, true, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UI.ink_button(Loc.t("astral_ask"), _consult.bind(d)))
		if answers.has(d):
			v.add_child(UI.separator(T.INK_L))
			v.add_child(UI.rich(str(answers[d]), 16))
		h.add_child(UI.scroll(p))


func _consult(d: String) -> void:
	var cid := _case_id()
	if cid == "":
		return
	var case_data := GameData.get_case(cid)
	match d:
		"thoth":
			answers[d] = _thoth(case_data)
		"anubis":
			answers[d] = _hint(case_data, "anubis", Loc.t("anubis_default"))
		"maat":
			answers[d] = _maat(case_data)
	refresh()


func _hint(case_data: Dictionary, deity: String, fallback: String) -> String:
	for h in case_data.get("hints", []):
		if h.deity == deity and Cond.check(h.get("when", true), GameState):
			return str(h.text)
	return fallback


func _thoth(case_data: Dictionary) -> String:
	var t := _hint(case_data, "thoth", "")
	if t != "":
		return t
	for ev in case_data.evidence:
		if GameState.has_evidence(ev.id):
			if not GameState.is_inspected(ev.id):
				return Loc.t("thoth_uninspected", [ev.title])
			for a in ev.get("inspect", []):
				if not GameState.is_revealed("%s.%s" % [ev.id, a.id]):
					return Loc.t("thoth_hidden_side", [ev.title])
	for c in case_data.get("comparisons", []):
		var p: Array = c.pair
		if GameState.has_evidence(str(p[0])) and GameState.has_evidence(str(p[1])) and c.has("hint") \
				and not GameState.was_compared("%s+%s" % [p[0], p[1]]):
			return "„%s”" % c.hint
	for br in case_data.get("investigation", []) + case_data.get("encounters", []):
		if Cond.check(br.get("unlock", true), GameState) and Dlg.has_new(case_data, br.dialogue, GameState):
			return Loc.t("thoth_untold", [br.title])
	return Loc.t("thoth_complete")


func _maat(case_data: Dictionary) -> String:
	var comp := Judgment.compute(case_data, GameState)
	var lines := []
	for pd in GameData.temple.get("params", []):
		lines.append("%s %s: %d" % [pd.glyph, pd.label, int(round(float(comp.params.get(pd.id, 0))))])
	var truth: float = comp.params.truth
	var verdict := Loc.t("maat_low")
	if truth >= 75:
		verdict = Loc.t("maat_high")
	elif truth >= 50:
		verdict = Loc.t("maat_mid")
	return "%s\n\n%s" % ["\n".join(lines), verdict]
